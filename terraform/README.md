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
github_owner = "your-github-user-or-org"
github_repo  = "gcp-html-terraform-cicd"
```

## Local Terraform commands

```bash
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```

## State management

### Option 1: local state (for learning/demo)

Local state is simple for learning, but it is not recommended for shared or production use. It stores state locally in your workstation.

### Option 2: Google Cloud Storage remote backend (recommended)

Create a GCS bucket and configure Terraform backend:

```bash
PROJECT_ID="your-gcp-project-id"
BUCKET_NAME="${PROJECT_ID}-tfstate"
REGION="asia-south1"

gcloud storage buckets create "gs://${BUCKET_NAME}" --project="${PROJECT_ID}" --location="${REGION}" --uniform-bucket-level-access
```

Then add backend configuration in `main.tf`:

```hcl
terraform {
  backend "gcs" {
    bucket = "your-terraform-state-bucket"
    prefix = "gcp-html-demo"
  }
}
```

Run:

```bash
terraform init -reconfigure
```

Do not commit `terraform.tfstate` or any state files to Git.

## Outputs

After apply, review useful outputs:

```bash
terraform output vm_name
terraform output vm_external_ip
terraform output application_url
```
