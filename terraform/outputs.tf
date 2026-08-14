output "vm_name" {
  description = "Name of the Compute Engine VM."
  value       = google_compute_instance.vm.name
}

output "vm_zone" {
  description = "Zone where the Compute Engine VM is running."
  value       = google_compute_instance.vm.zone
}

output "vm_external_ip" {
  description = "External IP address of the Compute Engine VM."
  value       = google_compute_instance.vm.network_interface[0].access_config[0].nat_ip
}

output "application_url" {
  description = "Public URL for the deployed application."
  value       = "http://${google_compute_instance.vm.network_interface[0].access_config[0].nat_ip}"
}

output "deployment_service_account_email" {
  description = "Email of the dedicated deployment service account."
  value       = google_service_account.deployment_sa.email
}

output "workload_identity_provider" {
  description = "Full Workload Identity Provider resource name for GitHub Actions authentication."
  value       = google_iam_workload_identity_pool_provider.github.name
}
