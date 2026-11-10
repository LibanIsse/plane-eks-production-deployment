#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

export AWS_PROFILE="${AWS_PROFILE:-eks-iac}"
export AWS_REGION="${AWS_REGION:-eu-west-2}"
CLUSTER_NAME="${CLUSTER_NAME:-plane-eks}"

echo "===== 1. Checking prerequisites ====="
for tool in aws terraform kubectl helm python3; do
  command -v "$tool" >/dev/null || {
    echo "Missing required tool: $tool"
    exit 1
  }
done

echo "===== 2. Connecting to EKS ====="
aws sts get-caller-identity --query '{Account:Account,Arn:Arn}' --output table

aws eks update-kubeconfig \
  --name "$CLUSTER_NAME" \
  --region "$AWS_REGION" \
  --profile "$AWS_PROFILE"

kubectl get nodes

echo "===== 3. Generating Plane configuration ====="
python3 scripts/generate-plane-config.py

echo "===== 4. Installing Argo CD ====="
helm repo add argo https://argoproj.github.io/argo-helm --force-update

helm upgrade --install argocd argo/argo-cd \
  --namespace argocd \
  --create-namespace \
  --version 10.10.5 \
  --values helm/values/argocd-values.yaml \
  --wait \
  --timeout 10m

echo "===== 5. Registering root Application ====="
kubectl apply -f gitops/root-app.yaml

echo "===== 6. Synchronising platform-root ====="
kubectl -n argocd patch application platform-root \
  --type merge \
  -p '{"operation":{"sync":{"revision":"main"}}}'

echo "===== 7. Checking GitOps status ====="
kubectl get applications -n argocd

echo "Bootstrap completed. Child Applications require their own sync policies."
