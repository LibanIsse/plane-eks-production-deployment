#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

export AWS_PROFILE="${AWS_PROFILE:-eks-iac}"
export AWS_REGION="${AWS_REGION:-eu-west-2}"
export AWS_PAGER=""
CLUSTER_NAME="${CLUSTER_NAME:-plane-eks}"

log() {
  printf '\n===== %s =====\n' "$1"
}

sync_app() {
  local app="$1"

  log "Synchronising $app"

  kubectl -n argocd patch application "$app" \
    --type merge \
    -p '{"operation":{"sync":{}}}'
}

wait_app() {
  local app="$1"

  for i in {1..60}; do
    if kubectl -n argocd get application "$app" \
      >/dev/null 2>&1; then
      return 0
    fi
    sleep 5
  done

  echo "ERROR: Argo CD Application $app was not created."
  exit 1
}

wait_deployment() {
  local namespace="$1"
  local deployment="$2"

  for i in {1..60}; do
    if kubectl -n "$namespace" get deployment "$deployment" \
      >/dev/null 2>&1; then
      kubectl -n "$namespace" rollout status \
        "deployment/$deployment" --timeout=300s
      return 0
    fi
    sleep 5
  done

  echo "ERROR: Deployment $namespace/$deployment not found."
  exit 1
}

wait_certificate() {
  local namespace="$1"

  for i in {1..60}; do
    if kubectl -n "$namespace" get certificate plane-tls \
      >/dev/null 2>&1; then
      kubectl -n "$namespace" wait \
        --for=condition=Ready \
        certificate/plane-tls \
        --timeout=600s
      return 0
    fi
    sleep 5
  done

  echo "ERROR: TLS certificate not created in $namespace."
  exit 1
}

log "1. Checking prerequisites"

for tool in aws terraform kubectl helm python3; do
  command -v "$tool" >/dev/null || {
    echo "Missing required tool: $tool"
    exit 1
  }
done

aws sts get-caller-identity \
  --query '{Account:Account,Arn:Arn}' \
  --output table

log "2. Connecting to EKS"

aws eks update-kubeconfig \
  --name "$CLUSTER_NAME" \
  --region "$AWS_REGION" \
  --profile "$AWS_PROFILE"

kubectl get nodes

log "3. Discovering VPC ID"

VPC_ID=$(aws eks describe-cluster \
  --name "$CLUSTER_NAME" \
  --region "$AWS_REGION" \
  --query 'cluster.resourcesVpcConfig.vpcId' \
  --output text)

if [[ -z "$VPC_ID" || "$VPC_ID" == "None" ]]; then
  echo "ERROR: Could not discover the EKS VPC."
  exit 1
fi

export VPC_ID
echo "VPC discovered: $VPC_ID"

log "4. Generating environment configuration"

python3 scripts/generate-plane-config.py

log "5. Installing Argo CD"

helm repo add argo https://argoproj.github.io/argo-helm \
  --force-update

helm upgrade --install argocd argo/argo-cd \
  --namespace argocd \
  --create-namespace \
  --version 10.10.5 \
  --values helm/values/argocd-values.yaml \
  --wait \
  --timeout 10m

log "6. Registering platform-root"

kubectl apply -f gitops/root-app.yaml
sync_app platform-root

for app in \
  metrics-server \
  external-secrets \
  plane-secretstore \
  cert-manager \
  aws-load-balancer-controller \
  external-dns \
  plane-tls \
  nginx-ingress
do
  wait_app "$app"
done

log "7. Deploying foundation controllers"

for app in \
  metrics-server \
  external-secrets \
  plane-secretstore \
  cert-manager
do
  sync_app "$app"
done

for deployment in \
  external-secrets \
  external-secrets-webhook \
  external-secrets-cert-controller
do
  wait_deployment external-secrets "$deployment"
done

for deployment in \
  cert-manager \
  cert-manager-webhook \
  cert-manager-cainjector
do
  wait_deployment cert-manager "$deployment"
done

kubectl -n plane wait \
  --for=condition=Ready \
  secretstore/aws-secretsmanager \
  --timeout=300s

log "8. Injecting dynamic AWS controller VPC ID"

python3 - <<'PY'
import json
import os
import subprocess

name = "aws-load-balancer-controller"

app = json.loads(subprocess.check_output([
    "kubectl", "-n", "argocd",
    "get", "application", name, "-o", "json"
], text=True))

helm = app["spec"]["sources"][0].get("helm", {})

parameters = [
    p for p in helm.get("parameters", [])
    if p.get("name") != "vpcId"
]

parameters.append({
    "name": "vpcId",
    "value": os.environ["VPC_ID"]
})

patch = [{
    "op": "add",
    "path": "/spec/sources/0/helm/parameters",
    "value": parameters
}]

subprocess.run([
    "kubectl", "-n", "argocd",
    "patch", "application", name,
    "--type=json",
    "-p", json.dumps(patch)
], check=True)
PY

sync_app aws-load-balancer-controller

wait_deployment kube-system aws-load-balancer-controller

log "9. Issuing TLS certificates"

sync_app plane-tls

wait_certificate nginx-ingress
wait_certificate plane

log "10. Deploying NGINX and ExternalDNS"

sync_app nginx-ingress
sync_app external-dns

wait_deployment nginx-ingress nginx-ingress-controller
wait_deployment external-dns external-dns

log "11. Synchronising Plane secrets"

kubectl -n plane apply \
  -f gitops/generated/externalsecret.yaml \
  -f gitops/generated/plane-url.yaml

kubectl -n plane wait \
  --for=condition=Ready \
  externalsecret --all \
  --timeout=300s

log "12. Deploying Plane through Argo CD"

kubectl apply -f gitops/generated/plane-application.json

wait_app plane
sync_app plane

log "13. Waiting for database migration"

for i in {1..60}; do
  if kubectl -n plane get job plane-api-migrate-1 \
    >/dev/null 2>&1; then
    break
  fi
  sleep 5
done

kubectl -n plane wait \
  --for=condition=complete \
  job/plane-api-migrate-1 \
  --timeout=900s

log "14. Waiting for Plane workloads"

for deployment in \
  plane-admin-wl \
  plane-api-wl \
  plane-beat-worker-wl \
  plane-live-wl \
  plane-space-wl \
  plane-web-wl \
  plane-worker-wl
do
  wait_deployment plane "$deployment"
done

log "15. Final GitOps status"

kubectl -n argocd get applications
kubectl -n plane get deployments
kubectl -n plane get ingress
kubectl get certificates -A

echo
echo "Bootstrap deployment stages completed."
echo "Review Argo CD sync health and HTTPS before sign-off."
