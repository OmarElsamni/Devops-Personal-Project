#!/bin/bash
# Deploy application to Kubernetes

set -e

AWS_REGION=${AWS_REGION:-us-east-1}
CLUSTER_NAME=${CLUSTER_NAME:-devops-task-manager}
IMAGE_TAG=${IMAGE_TAG:-latest}

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Get AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

print_info "Deploying application to Kubernetes..."
print_info "Cluster: $CLUSTER_NAME"
print_info "Image Tag: $IMAGE_TAG"

# Update kubeconfig
print_info "Updating kubeconfig..."
aws eks update-kubeconfig --region $AWS_REGION --name $CLUSTER_NAME

# Create temporary deployment files with updated image tags
print_info "Preparing deployment manifests..."

cp kubernetes/app/backend-deployment.yaml /tmp/backend-deployment.yaml
cp kubernetes/app/frontend-deployment.yaml /tmp/frontend-deployment.yaml

sed -i.bak "s|\${ECR_REGISTRY}|${ECR_REGISTRY}|g" /tmp/backend-deployment.yaml
sed -i.bak "s|\${IMAGE_TAG}|${IMAGE_TAG}|g" /tmp/backend-deployment.yaml
sed -i.bak "s|\${ECR_REGISTRY}|${ECR_REGISTRY}|g" /tmp/frontend-deployment.yaml
sed -i.bak "s|\${IMAGE_TAG}|${IMAGE_TAG}|g" /tmp/frontend-deployment.yaml

# Apply deployments
print_info "Applying Kubernetes manifests..."
kubectl apply -f kubernetes/namespaces/namespaces.yaml
kubectl apply -f kubernetes/app/configmap.yaml
kubectl apply -f /tmp/backend-deployment.yaml
kubectl apply -f /tmp/frontend-deployment.yaml
kubectl apply -f kubernetes/app/ingress.yaml
kubectl apply -f kubernetes/app/hpa.yaml
kubectl apply -f kubernetes/app/networkpolicy.yaml
kubectl apply -f kubernetes/monitoring/servicemonitor.yaml

# Wait for deployments
print_info "Waiting for deployments to be ready..."
kubectl rollout status deployment/backend -n task-manager --timeout=5m
kubectl rollout status deployment/frontend -n task-manager --timeout=5m

# Check status
print_info "Deployment status:"
kubectl get pods -n task-manager
kubectl get svc -n task-manager
kubectl get ingress -n task-manager

# Get application URL
print_info "Getting application URL..."
INGRESS_URL=$(kubectl get ingress task-manager-ingress -n task-manager -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

echo ""
print_info "======================================"
print_info "Deployment Complete!"
print_info "======================================"
echo ""
print_info "Application URL: http://$INGRESS_URL"
print_info "Backend API: http://$INGRESS_URL/api"
print_info "Frontend: http://$INGRESS_URL"

# Cleanup
rm -f /tmp/backend-deployment.yaml /tmp/backend-deployment.yaml.bak
rm -f /tmp/frontend-deployment.yaml /tmp/frontend-deployment.yaml.bak

