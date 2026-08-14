variable "project_id" {
  description = "The GCP project ID where the infrastructure will be created."
  type        = string
}

variable "region" {
  description = "The GCP region for the network and VM resources."
  type        = string
  default     = "asia-south1"
}

variable "zone" {
  description = "The GCP zone for the VM resource."
  type        = string
  default     = "asia-south1-a"
}

variable "machine_type" {
  description = "Machine type for the demo VM."
  type        = string
  default     = "e2-micro"
}

variable "vm_name" {
  description = "Name of the Compute Engine VM."
  type        = string
  default     = "html-demo-vm"
}

variable "network_name" {
  description = "The VPC network name used by the demo."
  type        = string
  default     = "gcp-demo-vpc"
}

variable "subnet_cidr" {
  description = "CIDR block for the demo subnet."
  type        = string
  default     = "10.0.0.0/24"
}

variable "deployment_service_account_id" {
  description = "Short ID for the service account used by GitHub Actions."
  type        = string
  default     = "gcp-demo-deployer"
}

variable "wif_pool_id" {
  description = "Workload Identity Pool ID for GitHub OIDC authentication."
  type        = string
  default     = "github-actions-pool"
}

variable "wif_provider_id" {
  description = "Workload Identity Provider ID for GitHub OIDC authentication."
  type        = string
  default     = "github-oidc"
}

variable "github_owner" {
  description = "GitHub repository owner or organization (for example: my-user or my-org)."
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name (for example: gcp-html-terraform-cicd)."
  type        = string
}
