# GCP HTML Terraform CI/CD Demo

This repository contains a simple static web application deployed to a Google Cloud Platform Compute Engine VM using Terraform and GitHub Actions. The architecture uses GitHub OIDC (Workload Identity Federation) instead of a long-lived service-account JSON key.

## Project goals

- Deploy a simple static HTML landing page to a GCP VM
- Use Terraform for infrastructure provisioning
- Use GitHub Actions for CI/CD
- Securely authenticate GitHub Actions to GCP with Workload Identity Federation
- Keep the deployment simple and beginner-friendly

## Repository structure

```text
.
├── app/
│   ├── index.html
│   ├── styles.css
│   └── app.js
├── scripts/
│   ├── deploy.sh
│   └── health-check.sh
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── versions.tf
│   ├── terraform.tfvars.example
│   └── README.md
├── .github/
│   └── workflows/
│       └── deploy.yml
├── cloudbuild.yaml
├── .gitignore
├── README.md
├── architecture.md
└── LICENSE
```

Two independent, equivalent CI/CD paths are provided: GitHub Actions (`.github/workflows/deploy.yml`, using GitHub OIDC) and Google Cloud Build (`cloudbuild.yaml`, using the deployment service account directly). You can use either, or both.

## Prerequisites

Before you begin, make sure you have:

- A Google Cloud Platform account
- A GCP project with billing enabled
- A GitHub account and repository
- Terraform installed locally
- Google Cloud CLI (`gcloud`) installed locally
- Git installed
- Access to run commands in your terminal

## Step 1 — Clone repository

```bash
git clone <your-repository-url>
cd simple_app_terraform_Deployment
```

## Step 2 — Configure GCP

1. Create a new GCP project or select an existing one.
2. Ensure billing is enabled.
3. Enable the required APIs (the Terraform configuration does this automatically for the needed services).
4. Save your project ID, region, and zone.

Example values:

```bash
export PROJECT_ID="your-gcp-project-id"
export REGION="asia-south1"
export ZONE="asia-south1-a"
```

## Step 3 — Configure Terraform

Copy the example variables file and update it:

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your values:

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

## Step 4 — Create GCP authentication

This project uses GitHub OIDC with Workload Identity Federation. Do not use a long-lived service account JSON key.

### Create the Terraform state bucket (one-time)

GitHub Actions runners are ephemeral, so Terraform state must live in GCS rather than on disk. Create the bucket once, before the first `terraform init` (see `terraform/README.md` for the full command including the bucket-versioning step):

```bash
PROJECT_ID="your-gcp-project-id"
gcloud storage buckets create "gs://${PROJECT_ID}-tfstate" \
  --project="${PROJECT_ID}" \
  --location="asia-south1" \
  --uniform-bucket-level-access
```

### Create the Terraform identity resources

Run the Terraform configuration locally once to create the Workload Identity Pool and Provider and the deployment service account:

```bash
cd terraform
terraform init \
  -backend-config="bucket=your-gcp-project-id-tfstate" \
  -backend-config="prefix=simple-app-terraform-deployment"
terraform plan
terraform apply
```

This creates:

- A dedicated deployment service account
- A Workload Identity Pool
- A Workload Identity Provider
- IAM bindings that allow GitHub Actions to impersonate the deployment service account
- A grant allowing the deployment service account to read/write the Terraform state bucket, so subsequent GitHub Actions runs can share state with this initial local run

The Terraform outputs include the IAM provider resource name and the service account email.

## Step 5 — Configure GitHub

In your GitHub repository, add the following repository variables:

```text
GCP_PROJECT_ID
GCP_REGION
GCP_ZONE
GCP_VM_NAME
GCP_WORKLOAD_IDENTITY_PROVIDER
GCP_SERVICE_ACCOUNT
```

Set them to values like:

```text
GCP_PROJECT_ID = your-gcp-project-id
GCP_REGION = asia-south1
GCP_ZONE = asia-south1-a
GCP_VM_NAME = html-demo-vm
GCP_WORKLOAD_IDENTITY_PROVIDER = projects/123456789012/locations/global/workloadIdentityPools/github-actions-pool/providers/github-oidc
GCP_SERVICE_ACCOUNT = gcp-demo-deployer@your-gcp-project-id.iam.gserviceaccount.com
```

The GitHub repository value must be restricted to the exact repository and branch:

```text
OWNER/REPOSITORY
refs/heads/main
```

This is enforced by the IAM attribute condition in Terraform.

## Step 6 — Run Terraform locally

Use these commands from the `terraform` directory:

```bash
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```

After apply, get the URL:

```bash
terraform output application_url
```

## Step 7 — Access the application

Open the value returned by:

```bash
terraform output application_url
```

Example:

```text
http://34.123.45.67
```

## Step 8 — Push to GitHub

When you are ready, push the code to the `main` branch:

```bash
git add .
git commit -m "Initial GCP Terraform CI/CD application"
git push origin main
```

## Step 9 — GitHub Actions

Once the push occurs, GitHub Actions runs automatically:

1. Checks out the code
2. Validates the HTML files
3. Runs `terraform fmt -check`
4. Authenticates to GCP using GitHub OIDC
5. Runs `terraform init`
6. Runs `terraform validate`
7. Runs `terraform plan`
8. Runs `terraform apply`
9. Copies the HTML files to the Compute Engine VM
10. Reloads nginx
11. Performs a health check
12. Fails if the app is not reachable

## Optional: Google Cloud Build

`cloudbuild.yaml` at the repository root runs the same steps as the GitHub Actions workflow, as an alternative or additional trigger. It authenticates as the deployment service account directly (no OIDC needed, since Cloud Build already runs inside GCP), so it reuses the service account and state bucket created in Step 4.

To wire it up:

1. Enable the Cloud Build API on your project:
   ```bash
   gcloud services enable cloudbuild.googleapis.com
   ```
2. Let Cloud Build act as the deployment service account. Grant your own user (or whoever creates the trigger) the ability to do so:
   ```bash
   gcloud iam service-accounts add-iam-policy-binding \
     gcp-demo-deployer@your-gcp-project-id.iam.gserviceaccount.com \
     --member="user:you@example.com" \
     --role="roles/iam.serviceAccountUser"
   ```
3. Connect this GitHub repository to Cloud Build and create a trigger pointing at `cloudbuild.yaml` (Console: Cloud Build → Triggers → Connect Repository), setting the trigger's service account to `gcp-demo-deployer@your-gcp-project-id.iam.gserviceaccount.com`.
4. Review the `substitutions` block at the top of `cloudbuild.yaml` — update `_TFSTATE_BUCKET`, `_GITHUB_OWNER`, `_GITHUB_REPO`, and `_DEPLOYMENT_SA_EMAIL` to match your values (they default to the values used elsewhere in this README).

You do not need to repeat Step 4's local `terraform apply` for Cloud Build — the service account and state bucket it created are shared by both pipelines.

## Deployment architecture

This project uses a very simple stack:

- 1 GCP VPC and subnet
- 1 firewall rule allowing HTTP on port 80
- 1 Ubuntu VM
- Nginx to serve the HTML page
- Terraform provisions infrastructure
- GitHub Actions or Cloud Build deploys the app

## Security notes

- No service-account JSON keys are stored in GitHub secrets
- No passwords or secrets are committed to the repository
- GitHub OIDC is used to authenticate securely
- IAM permissions follow least-privilege principles
- The repository and branch are restricted in the Workload Identity Federation configuration

## Common commands

### Local Terraform

```bash
cd terraform
terraform init
terraform plan
terraform apply
terraform output
```

### Deploy locally

```bash
./scripts/deploy.sh html-demo-vm asia-south1-a your-gcp-project-id
```

### Health check

```bash
./scripts/health-check.sh http://<vm-external-ip>
```

## Troubleshooting

### Terraform authentication failure

- Verify you are authenticated with `gcloud auth application-default login`
- Confirm the GCP project ID is correct
- Ensure billing is enabled

### GitHub OIDC failure

- Check the `GCP_WORKLOAD_IDENTITY_PROVIDER` value in GitHub Variables
- Confirm the repository name and owner match the Terraform attribute condition
- Ensure the branch is `main`

### VM not reachable

- Check the external IP using `terraform output vm_external_ip`
- Confirm the firewall allows TCP 80
- Confirm nginx is running on the VM

### Nginx not running

```bash
sudo systemctl status nginx
sudo systemctl restart nginx
```

### Permission denied during deployment

- Confirm the deployment service account has the needed IAM roles
- Ensure the GitHub Actions workflow has the correct permissions

### Terraform state problems

- Use a GCS remote backend for production
- Do not commit `*.tfstate` files to Git
- Use `terraform init -reconfigure` after backend changes

## License

This project is intended for learning and demonstration purposes.
