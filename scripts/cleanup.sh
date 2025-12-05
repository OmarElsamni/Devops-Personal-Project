#!/bin/bash
# Cleanup all resources

set -e

AWS_REGION=${AWS_REGION:-us-east-1}
CLUSTER_NAME=${CLUSTER_NAME:-devops-task-manager}

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo ""
print_warn "======================================"
print_warn "WARNING: This will destroy all resources!"
print_warn "======================================"
echo ""

read -p "Are you sure you want to continue? (type 'yes' to confirm): " confirm
if [ "$confirm" != "yes" ]; then
    print_info "Cleanup cancelled"
    exit 0
fi

# Update kubeconfig
print_info "Updating kubeconfig..."
aws eks update-kubeconfig --region $AWS_REGION --name $CLUSTER_NAME 2>/dev/null || true

# Delete Kubernetes resources
print_info "Deleting Kubernetes resources..."
kubectl delete namespace task-manager --ignore-not-found=true
kubectl delete namespace monitoring --ignore-not-found=true
kubectl delete namespace jenkins --ignore-not-found=true

# Uninstall Helm releases
print_info "Uninstalling Helm releases..."
helm uninstall prometheus -n monitoring --ignore-not-found 2>/dev/null || true
helm uninstall aws-load-balancer-controller -n kube-system --ignore-not-found 2>/dev/null || true

# Wait for LoadBalancers to be deleted
print_info "Waiting for LoadBalancers to be deleted..."
sleep 30

# Destroy Terraform infrastructure
print_info "Destroying Terraform infrastructure..."
cd terraform
terraform destroy \
    -var="aws_region=$AWS_REGION" \
    -var="cluster_name=$CLUSTER_NAME" \
    -auto-approve
cd ..

# Delete S3 bucket (optional - commented out for safety)
# print_info "Deleting S3 bucket..."
# aws s3 rb s3://devops-project-terraform-state --force

# Delete DynamoDB table (optional - commented out for safety)
# print_info "Deleting DynamoDB table..."
# aws dynamodb delete-table --table-name terraform-state-lock --region $AWS_REGION

print_info "======================================"
print_info "Cleanup Complete!"
print_info "======================================"

