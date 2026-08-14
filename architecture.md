# Architecture Overview

This project deploys a simple static HTML application to a single Ubuntu VM in Google Cloud Platform.

```text
                    Developer
                       |
                       | git push
                       v
                GitHub Repository
                       |
                       v
                GitHub Actions
                       |
              GitHub OIDC / WIF
                       |
                       v
             Google Cloud IAM
                       |
                       v
                 Terraform
                       |
          +------------+------------+
          |                         |
          v                         v
     Compute Engine             Firewall
          |                         |
          v                         v
        Nginx                   TCP 80
          |                         |
          v                         |
    HTML Application               |
                                  |
                                  v
                           Internet Users
```

## Components

### Developer

The developer pushes changes to the repository. This triggers the GitHub Actions workflow on the `main` branch.

### GitHub Repository

The source code for the HTML app and the deployment workflow lives here.

### GitHub Actions

GitHub Actions handles:

- Validation of the static app files
- Terraform formatting and validation
- Terraform plan and apply
- SSH-based deployment of the HTML files to the VM
- Application health checks

### GitHub OIDC / Workload Identity Federation

GitHub Actions authenticates to GCP without storing a service-account JSON key. Instead, GitHub exchanges an OIDC token for temporary credentials using a Workload Identity Pool and Provider.

### Google Cloud IAM

A dedicated deployment service account is created with least-privilege permissions needed to manage the VM and associated infrastructure.

### Terraform

Terraform provisions the infrastructure that the app depends on:

- VPC + subnet
- Firewall rule for port 80
- Compute Engine VM
- Workload Identity Federation resources
- Deployment service account and IAM bindings

### Compute Engine VM

The VM runs Ubuntu and installs Nginx so it can serve the static files publicly.

### Firewall

A firewall rule allows HTTP traffic from the internet to the VM on port 80 while avoiding unnecessary SSH exposure.

### Nginx

Nginx serves the HTML and CSS files from `/var/www/html`.

### HTML Application

The app is intentionally simple: a landing page describing the deployment method and showing the current status.

## Why this architecture

This is a beginner-friendly architecture that teaches the core principles of:

- Infrastructure as Code with Terraform
- Secure GitHub to GCP authentication using OIDC
- Static site hosting on a VM
- Automated deployment using CI/CD

It avoids unnecessary complexity such as Kubernetes, Docker, or managed web platforms.
