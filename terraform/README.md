# Terraform Deployment Guide

This directory contains the infrastructure-as-code for deploying a simple static HTML application to a Google Cloud Compute Engine VM.

## Files

- `main.tf` – network, firewall, IAM, Workload Identity Federation, and VM resources.
- `variables.tf` – configurable project and deployment settings.
- `outputs.tf` – outputs including VM IP and app URL.
- `versions.tf` – Terraform version and provider requirements.
- `terraform.tfvars.example` – example values you should copy to a local `terraform.tfvars` file.

## Requirements

- Terraform 1.5+
- Google Cloud CLI (`gcloud`)
- A GCP project with billing enabled
- A GitHub repository that will use GitHub OIDC authentication

## Create local variables

Copy the example file and adjust values for your environment:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Then edit `terraform.tfvars` with your values:

```hcl
project_id = "your-gcp-project-id"
region     = "asia-south1"
zone       = "asia-south1-a"
machine_type = "e2-micro"
vm_name    = "html-demo-vm"
github_owner = "GokulV2795"
github_repo  = "simple_app_terraform_Deployment"
tfstate_bucket_name = "your-gcp-project-id-tfstate"
```

## Local Terraform commands

`terraform init` requires the GCS backend config (see [State management](#state-management) below for the one-time bucket setup):

```bash
terraform init \
  -backend-config="bucket=your-gcp-project-id-tfstate" \
  -backend-config="prefix=simple-app-terraform-deployment"
terraform fmt
terraform validate
terraform plan
terraform apply
```

## State management

This project uses a Google Cloud Storage remote backend, required because GitHub Actions runners are ephemeral: without shared remote state, every CI run would start from scratch and try to recreate resources that already exist, and fail. `main.tf` declares an empty `backend "gcs" {}` block; the bucket and prefix are supplied at `terraform init` time via `-backend-config`, not hardcoded.

### One-time setup: create the state bucket

Before the very first `terraform init`, create the bucket manually (this bucket cannot be managed by the same Terraform state it holds):

```bash
PROJECT_ID="your-gcp-project-id"
BUCKET_NAME="${PROJECT_ID}-tfstate"
REGION="asia-south1"

gcloud storage buckets create "gs://${BUCKET_NAME}" \
  --project="${PROJECT_ID}" \
  --location="${REGION}" \
  --uniform-bucket-level-access

gcloud storage buckets update "gs://${BUCKET_NAME}" --versioning
```

Set `tfstate_bucket_name = "${BUCKET_NAME}"` in your `terraform.tfvars` — Terraform grants the deployment service account write access to this bucket automatically (`google_storage_bucket_iam_member.deployment_sa_tfstate_access` in `main.tf`), so subsequent GitHub Actions runs (which authenticate as that service account) can read and write state too.

### Initialize with the backend

```bash
terraform init \
  -backend-config="bucket=${BUCKET_NAME}" \
  -backend-config="prefix=simple-app-terraform-deployment"
```

The GitHub Actions workflow runs the equivalent command automatically using the `GCP_PROJECT_ID` repository variable.

Do not commit `terraform.tfstate` or any state files to Git.

## Outputs

After apply, review useful outputs:

```bash
terraform output vm_name
terraform output vm_external_ip
terraform output application_url
```
