#!/usr/bin/env bash
set -euo pipefail

URL="${1:-http://localhost}"

echo "Checking application health at ${URL}"

curl -fsS --max-time 20 "${URL}" | tee /tmp/gcp-demo-response.html >/dev/null

grep -q "GCP Terraform CI/CD Demo" /tmp/gcp-demo-response.html

grep -q "Application Status: Running" /tmp/gcp-demo-response.html

echo "Deployment successful: application responded with HTTP 200 and expected content."
