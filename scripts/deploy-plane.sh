#!/usr/bin/env bash
set -euo pipefail

# Retrieve the existing S3 bucket name from Terraform.
S3_BUCKET_NAME="$(terraform -chdir=infra output -raw s3_bucket_name)"
export S3_BUCKET_NAME

if [[ -z "$S3_BUCKET_NAME" ]]; then
  echo "Error: S3 bucket name is empty."
  exit 1
fi

# Deploy Plane using the existing Helm configuration.
envsubst '${S3_BUCKET_NAME}' < helm/values/plane.yaml |
  helm upgrade --install plane plane/plane-ce \
    --namespace plane \
    --version 1.8.5 \
    --wait \
    --timeout 10m \
    --values -

# Preserve HTTPS routing and correct Admin redirects.
kubectl patch ingress plane-ingress \
  --namespace plane \
  --type merge \
  --patch-file kubernetes/ingress/plane-tls-patch.yaml

# Validate the public Admin redirect.
curl -fsSL --max-time 15 \
  https://eks.libancloud.co.uk/god-mode/ \
  -o /dev/null

echo "Plane deployment and Ingress validation completed."
