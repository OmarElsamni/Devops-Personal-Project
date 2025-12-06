#!/bin/bash
# Deploy application with dynamic image tags

set -e

# Get parameters
IMAGE_TAG=${1:-latest}
AWS_REGION=${AWS_REGION:-us-east-1}

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

# Get AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
export IMAGE_TAG

print_info "Deploying with:"
print_info "  Registry: $ECR_REGISTRY"
print_info "  Image Tag: $IMAGE_TAG"

# Create temporary files with substituted values
print_info "Preparing deployment files..."

# Process backend deployment
envsubst < kubernetes/app/backend-deployment-template.yaml > /tmp/backend-deployment.yaml

# Process frontend deployment
envsubst < kubernetes/app/frontend-deployment-template.yaml > /tmp/frontend-deployment.yaml

# Apply deployments
print_info "Applying deployments..."
kubectl apply -f /tmp/backend-deployment.yaml
kubectl apply -f /tmp/frontend-deployment.yaml

# Cleanup temp files
rm /tmp/backend-deployment.yaml /tmp/frontend-deployment.yaml

print_info "Deployment complete!"
print_info "Check status: kubectl get pods -n task-manager"

