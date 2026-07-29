#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="k8s-app-platform"
IMAGE="k8s-node-app:0.1.0"

echo "==> Creating kind cluster"
kind create cluster --name "${CLUSTER_NAME}" --config kind-config.yaml

echo "==> Loading local image into cluster nodes"
kind load docker-image "${IMAGE}" --name "${CLUSTER_NAME}"

echo "==> Installing nginx ingress controller"
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

echo "==> Pinning controller to the node with kind's extraPortMappings"
# The controller binds a hostPort, so it MUST run on the control-plane node
# where kind maps host 8080 -> node 80. Without this it can schedule onto a
# worker and requests to localhost:8080 are reset.
kubectl -n ingress-nginx patch deployment ingress-nginx-controller --type merge -p '
spec:
  template:
    spec:
      nodeSelector:
        ingress-ready: "true"
        kubernetes.io/os: linux
      tolerations:
      - key: node-role.kubernetes.io/control-plane
        operator: Equal
        effect: NoSchedule
'

echo "==> Waiting for ingress controller"
kubectl -n ingress-nginx rollout status deployment ingress-nginx-controller --timeout=180s

echo "==> Deploying application"
kubectl apply -f k8s/base/

kubectl rollout status deployment/node-app --timeout=120s

echo "==> Done. Try: curl -s localhost:8080/"
