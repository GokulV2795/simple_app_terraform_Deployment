# Remote state bucket must be created manually before the first `terraform init`
# (see terraform/README.md). Bucket name and prefix are supplied via
# `terraform init -backend-config=...` so they aren't hardcoded here.
terraform {
  backend "gcs" {}
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

locals {
  api_services = [
    "compute.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "serviceusage.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "oslogin.googleapis.com",
    "iap.googleapis.com"
  ]
}

resource "google_project_service" "required" {
  for_each = toset(local.api_services)

  service = each.value

  disable_on_destroy = false
}

resource "google_compute_network" "main" {
  name                    = var.network_name
  auto_create_subnetworks = false

  depends_on = [google_project_service.required]
}

resource "google_compute_subnetwork" "main" {
  name          = "${var.network_name}-subnet"
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.main.id
}

resource "google_compute_firewall" "http_ingress" {
  name    = "allow-http-from-internet"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server"]
}

resource "google_compute_firewall" "iap_ssh_ingress" {
  name    = "allow-html-demo-iap-ssh"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  # IAP TCP forwarding always originates from this range.
  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["iap-ssh"]
}

resource "google_service_account" "deployment_sa" {
  account_id   = var.deployment_service_account_id
  display_name = "GitHub Actions deployment service account"
  description  = "Dedicated identity used by GitHub Actions to deploy the demo app."
}

resource "google_project_iam_member" "deployment_sa_compute_admin" {
  project = var.project_id
  role    = "roles/compute.instanceAdmin.v1"
  member  = "serviceAccount:${google_service_account.deployment_sa.email}"
}

resource "google_project_iam_member" "deployment_sa_sa_user" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.deployment_sa.email}"
}

resource "google_project_iam_member" "deployment_sa_iap_tunnel" {
  project = var.project_id
  role    = "roles/iap.tunnelResourceAccessor"
  member  = "serviceAccount:${google_service_account.deployment_sa.email}"
}

resource "google_project_iam_member" "deployment_sa_oslogin" {
  project = var.project_id
  role    = "roles/compute.osAdminLogin"
  member  = "serviceAccount:${google_service_account.deployment_sa.email}"
}

resource "google_project_iam_member" "deployment_sa_compute_viewer" {
  project = var.project_id
  role    = "roles/compute.viewer"
  member  = "serviceAccount:${google_service_account.deployment_sa.email}"
}

resource "google_storage_bucket_iam_member" "deployment_sa_tfstate_access" {
  bucket = var.tfstate_bucket_name
  role   = "roles/storage.objectUser"
  member = "serviceAccount:${google_service_account.deployment_sa.email}"
}

resource "google_iam_workload_identity_pool" "github" {
  project                   = var.project_id
  workload_identity_pool_id = var.wif_pool_id
  display_name              = "GitHub Actions Pool"
  description               = "Identity pool for GitHub Actions OIDC authentication"

  depends_on = [google_project_service.required]
}

resource "google_iam_workload_identity_pool_provider" "github" {
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = var.wif_provider_id
  display_name                       = "GitHub Actions OIDC Provider"
  description                        = "OIDC provider for GitHub Actions"

  attribute_mapping = {
    "google.subject"             = "assertion.sub"
    "attribute.repository"       = "assertion.repository"
    "attribute.ref"              = "assertion.ref"
    "attribute.repository_owner" = "assertion.repository_owner"
  }

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }

  attribute_condition = "attribute.repository == \"${var.github_owner}/${var.github_repo}\" && attribute.ref == \"refs/heads/main\""
}

resource "google_service_account_iam_member" "github_wif_binding" {
  service_account_id = google_service_account.deployment_sa.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${var.github_owner}/${var.github_repo}"
}

resource "google_compute_instance" "vm" {
  name         = var.vm_name
  machine_type = var.machine_type
  zone         = var.zone
  tags         = ["http-server", "iap-ssh"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 20
      type  = "pd-standard"
    }
  }

  network_interface {
    network    = google_compute_network.main.id
    subnetwork = google_compute_subnetwork.main.id

    access_config {
      # An external IP is required to access the app over HTTP.
    }
  }

  metadata = {
    "enable-oslogin" = "TRUE"
    "startup-script" = <<-EOT
      #!/bin/bash
      set -eux
      apt-get update
      DEBIAN_FRONTEND=noninteractive apt-get install -y nginx
      systemctl enable nginx
      systemctl start nginx
      cat > /var/www/html/index.html <<'HTML'
      <html><body><h1>GCP Terraform CI/CD Demo</h1><p>Application is initializing.</p></body></html>
      HTML
      chmod 0644 /var/www/html/index.html
      systemctl reload nginx
    EOT
  }

  service_account {
    email  = google_service_account.deployment_sa.email
    scopes = ["cloud-platform"]
  }

  depends_on = [
    google_project_service.required,
    google_compute_firewall.http_ingress,
    google_service_account.deployment_sa
  ]
}
