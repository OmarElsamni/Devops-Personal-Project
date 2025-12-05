#!/bin/bash
# Install Metrics Server for HPA

set -e

echo "Installing Metrics Server..."

kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

echo "Waiting for Metrics Server to be ready..."
kubectl wait --for=condition=ready pod -l k8s-app=metrics-server -n kube-system --timeout=300s

echo "Metrics Server installation complete!"
echo "Verify with: kubectl top nodes"

