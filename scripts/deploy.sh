#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 3 ]; then
  echo "Usage: $0 <vm_name> <vm_zone> <project_id>"
  exit 1
fi

VM_NAME="$1"
VM_ZONE="$2"
PROJECT_ID="$3"
REMOTE_DIR="/var/www/html"

echo "Deploying static site to VM ${VM_NAME} in zone ${VM_ZONE}..."

gcloud compute scp \
  --project="${PROJECT_ID}" \
  --zone="${VM_ZONE}" \
  --tunnel-through-iap \
  "app/index.html" "app/styles.css" \
  "ubuntu@${VM_NAME}:/tmp/"

gcloud compute ssh "${VM_NAME}" \
  --project="${PROJECT_ID}" \
  --zone="${VM_ZONE}" \
  --tunnel-through-iap \
  --command="sudo mkdir -p ${REMOTE_DIR}; sudo install -m 0644 /tmp/index.html ${REMOTE_DIR}/index.html; sudo install -m 0644 /tmp/styles.css ${REMOTE_DIR}/styles.css; sudo systemctl reload nginx || sudo systemctl restart nginx"

echo "Deployment complete."
