#!/bin/bash
# Build and push Docker images to ECR

set -e

AWS_REGION=${AWS_REGION:-us-east-1}
IMAGE_TAG=${IMAGE_TAG:-latest}

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

# Get AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

BACKEND_IMAGE="${ECR_REGISTRY}/production-task-manager-backend"
FRONTEND_IMAGE="${ECR_REGISTRY}/production-task-manager-frontend"

print_info "Building and pushing Docker images..."
print_info "Registry: $ECR_REGISTRY"
print_info "Image Tag: $IMAGE_TAG"

# Login to ECR
print_info "Logging into ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REGISTRY

# Build backend
print_info "Building backend image..."
cd backend
docker build -t $BACKEND_IMAGE:$IMAGE_TAG .
docker tag $BACKEND_IMAGE:$IMAGE_TAG $BACKEND_IMAGE:latest
cd ..

# Build frontend
print_info "Building frontend image..."
cd frontend
docker build -t $FRONTEND_IMAGE:$IMAGE_TAG .
docker tag $FRONTEND_IMAGE:$IMAGE_TAG $FRONTEND_IMAGE:latest
cd ..

# Push images
print_info "Pushing backend image..."
docker push $BACKEND_IMAGE:$IMAGE_TAG
docker push $BACKEND_IMAGE:latest

print_info "Pushing frontend image..."
docker push $FRONTEND_IMAGE:$IMAGE_TAG
docker push $FRONTEND_IMAGE:latest

print_info "======================================"
print_info "Build and Push Complete!"
print_info "======================================"
echo ""
print_info "Backend Image: $BACKEND_IMAGE:$IMAGE_TAG"
print_info "Frontend Image: $FRONTEND_IMAGE:$IMAGE_TAG"

