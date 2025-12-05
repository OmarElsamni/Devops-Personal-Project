#!/bin/bash
# Setup complete infrastructure

set -e

echo "======================================"
echo "DevOps Project Infrastructure Setup"
echo "======================================"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
AWS_REGION=${AWS_REGION:-us-east-1}
CLUSTER_NAME=${CLUSTER_NAME:-devops-task-manager}
DB_PASSWORD=${DB_PASSWORD:-$(openssl rand -base64 32)}

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
print_info "Checking prerequisites..."

command -v aws >/dev/null 2>&1 || { print_error "AWS CLI is required but not installed. Aborting."; exit 1; }
command -v terraform >/dev/null 2>&1 || { print_error "Terraform is required but not installed. Aborting."; exit 1; }
command -v kubectl >/dev/null 2>&1 || { print_error "kubectl is required but not installed. Aborting."; exit 1; }
command -v helm >/dev/null 2>&1 || { print_error "Helm is required but not installed. Aborting."; exit 1; }

print_info "All prerequisites satisfied!"

# Step 1: Create S3 bucket for Terraform state
print_info "Creating S3 bucket for Terraform state..."
aws s3api create-bucket \
    --bucket devops-project-terraform-state \
    --region $AWS_REGION \
    --create-bucket-configuration LocationConstraint=$AWS_REGION 2>/dev/null || print_warn "S3 bucket already exists"

aws s3api put-bucket-versioning \
    --bucket devops-project-terraform-state \
    --versioning-configuration Status=Enabled

# Create DynamoDB table for state locking
print_info "Creating DynamoDB table for state locking..."
aws dynamodb create-table \
    --table-name terraform-state-lock \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region $AWS_REGION 2>/dev/null || print_warn "DynamoDB table already exists"

# Step 2: Initialize and apply Terraform
print_info "Initializing Terraform..."
cd terraform

terraform init

print_info "Planning Terraform changes..."
terraform plan \
    -var="aws_region=$AWS_REGION" \
    -var="cluster_name=$CLUSTER_NAME" \
    -var="db_password=$DB_PASSWORD" \
    -out=tfplan

read -p "Do you want to apply these changes? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    print_error "Terraform apply cancelled"
    exit 1
fi

print_info "Applying Terraform configuration..."
terraform apply tfplan

print_info "Saving Terraform outputs..."
terraform output -json > ../outputs.json

cd ..

# Step 3: Configure kubectl
print_info "Configuring kubectl..."
aws eks update-kubeconfig --region $AWS_REGION --name $CLUSTER_NAME

# Step 4: Install AWS Load Balancer Controller
print_info "Installing AWS Load Balancer Controller..."
cd kubernetes/aws-load-balancer-controller
chmod +x install.sh
./install.sh $CLUSTER_NAME $AWS_REGION
cd ../..

# Step 5: Install Metrics Server
print_info "Installing Metrics Server..."
cd kubernetes/metrics-server
chmod +x install.sh
./install.sh
cd ../..

# Step 6: Create namespaces
print_info "Creating Kubernetes namespaces..."
kubectl apply -f kubernetes/namespaces/namespaces.yaml

# Step 7: Install Prometheus and Grafana
print_info "Installing Prometheus and Grafana..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm install prometheus prometheus-community/kube-prometheus-stack \
    -f kubernetes/monitoring/prometheus-values.yaml \
    -n monitoring \
    --create-namespace

# Step 8: Create database secret
print_info "Creating database secret..."
RDS_ENDPOINT=$(terraform -chdir=terraform output -raw rds_endpoint)

kubectl create secret generic database-secret \
    --from-literal=host=$RDS_ENDPOINT \
    --from-literal=database=taskdb \
    --from-literal=username=dbadmin \
    --from-literal=password=$DB_PASSWORD \
    -n task-manager --dry-run=client -o yaml | kubectl apply -f -

# Step 9: Setup Jenkins (optional)
read -p "Do you want to install Jenkins? (yes/no): " install_jenkins
if [ "$install_jenkins" == "yes" ]; then
    print_info "Setting up Jenkins..."
    cd jenkins
    chmod +x setup-jenkins.sh
    ./setup-jenkins.sh
    cd ..
fi

# Print summary
print_info "======================================"
print_info "Infrastructure Setup Complete!"
print_info "======================================"
echo ""
print_info "Cluster Name: $CLUSTER_NAME"
print_info "AWS Region: $AWS_REGION"
print_info "Database Password: $DB_PASSWORD (SAVE THIS!)"
echo ""
print_info "Next steps:"
echo "1. Build and push Docker images to ECR"
echo "2. Deploy application: kubectl apply -f kubernetes/app/"
echo "3. Access Grafana: kubectl get svc -n monitoring prometheus-grafana"
echo "4. Get Grafana password: kubectl get secret -n monitoring prometheus-grafana -o jsonpath='{.data.admin-password}' | base64 -d"
echo ""
print_info "Useful commands:"
echo "  kubectl get pods -A"
echo "  kubectl get svc -A"
echo "  kubectl logs -f <pod-name> -n <namespace>"

