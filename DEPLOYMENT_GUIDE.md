# Deployment Guide

This guide provides step-by-step instructions for deploying the DevOps Task Manager application to production.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Initial Setup](#initial-setup)
3. [Infrastructure Deployment](#infrastructure-deployment)
4. [Application Deployment](#application-deployment)
5. [CI/CD Setup](#cicd-setup)
6. [Monitoring Setup](#monitoring-setup)
7. [Post-Deployment Verification](#post-deployment-verification)
8. [Rollback Procedures](#rollback-procedures)

## Prerequisites

### Required Tools

Install the following tools before proceeding:

```bash
# AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Terraform
wget https://releases.hashicorp.com/terraform/1.6.6/terraform_1.6.6_linux_amd64.zip
unzip terraform_1.6.6_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# eksctl
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin

# Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
```

### AWS Account Setup

1. **Create IAM User** with the following permissions:
   - AdministratorAccess (for initial setup)
   - Or attach these policies:
     - AmazonEKSClusterPolicy
     - AmazonEKSServicePolicy
     - AmazonEC2FullAccess
     - AmazonVPCFullAccess
     - AmazonRDSFullAccess
     - AmazonS3FullAccess
     - IAMFullAccess

2. **Configure AWS CLI**:
```bash
aws configure
# AWS Access Key ID: YOUR_ACCESS_KEY
# AWS Secret Access Key: YOUR_SECRET_KEY
# Default region: us-east-1
# Default output format: json
```

3. **Verify Configuration**:
```bash
aws sts get-caller-identity
```

## Initial Setup

### 1. Clone Repository

```bash
git clone https://github.com/YOUR_USERNAME/devops-task-manager.git
cd devops-task-manager
```

### 2. Set Environment Variables

```bash
export AWS_REGION=us-east-1
export CLUSTER_NAME=devops-task-manager
export ENVIRONMENT=production
export DB_PASSWORD=$(openssl rand -base64 32)

# Save these for later use
echo "CLUSTER_NAME=$CLUSTER_NAME" >> .env
echo "AWS_REGION=$AWS_REGION" >> .env
echo "DB_PASSWORD=$DB_PASSWORD" >> .env

# IMPORTANT: Save DB_PASSWORD securely!
echo "Database Password: $DB_PASSWORD" > CREDENTIALS.txt
chmod 600 CREDENTIALS.txt
```

### 3. Make Scripts Executable

```bash
find scripts/ -type f -name "*.sh" -exec chmod +x {} \;
find kubernetes/ -type f -name "*.sh" -exec chmod +x {} \;
find jenkins/ -type f -name "*.sh" -exec chmod +x {} \;
```

## Infrastructure Deployment

### Option A: Automated Setup (Recommended for First-Time)

```bash
./scripts/setup-infrastructure.sh
```

This script handles everything automatically. Skip to [Application Deployment](#application-deployment).

### Option B: Manual Step-by-Step Setup

#### Step 1: Create Terraform Backend

```bash
# Create S3 bucket for Terraform state
aws s3api create-bucket \
    --bucket devops-project-terraform-state \
    --region $AWS_REGION

# Enable versioning
aws s3api put-bucket-versioning \
    --bucket devops-project-terraform-state \
    --versioning-configuration Status=Enabled

# Create DynamoDB table for locking
aws dynamodb create-table \
    --table-name terraform-state-lock \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region $AWS_REGION
```

#### Step 2: Deploy Infrastructure with Terraform

```bash
cd terraform

# Initialize Terraform
terraform init

# Review the plan
terraform plan \
    -var="aws_region=$AWS_REGION" \
    -var="cluster_name=$CLUSTER_NAME" \
    -var="db_password=$DB_PASSWORD" \
    -out=tfplan

# Apply the configuration
terraform apply tfplan

# Save outputs
terraform output -json > ../terraform-outputs.json

cd ..
```

**Expected Resources Created**:
- VPC with 3 public, 3 private, and 3 database subnets
- NAT Gateways in each AZ
- EKS cluster with managed node groups
- RDS PostgreSQL database (Multi-AZ)
- ECR repositories for frontend and backend
- S3 bucket for application assets
- Security groups and IAM roles

#### Step 3: Configure kubectl

```bash
aws eks update-kubeconfig \
    --region $AWS_REGION \
    --name $CLUSTER_NAME

# Verify connection
kubectl get nodes
kubectl get namespaces
```

#### Step 4: Install AWS Load Balancer Controller

```bash
cd kubernetes/aws-load-balancer-controller
./install.sh $CLUSTER_NAME $AWS_REGION
cd ../..

# Verify installation
kubectl get deployment -n kube-system aws-load-balancer-controller
```

#### Step 5: Install Metrics Server

```bash
cd kubernetes/metrics-server
./install.sh
cd ../..

# Verify installation
kubectl get deployment metrics-server -n kube-system
```

#### Step 6: Setup Monitoring Stack

```bash
# Add Helm repository
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install Prometheus and Grafana
helm install prometheus prometheus-community/kube-prometheus-stack \
    -f kubernetes/monitoring/prometheus-values.yaml \
    -n monitoring \
    --create-namespace

# Wait for pods to be ready
kubectl wait --for=condition=ready pod \
    -l app.kubernetes.io/name=prometheus \
    -n monitoring \
    --timeout=300s
```

## Application Deployment

### Step 1: Create Kubernetes Namespaces

```bash
kubectl apply -f kubernetes/namespaces/namespaces.yaml
```

### Step 2: Create Database Secret

```bash
# Get RDS endpoint from Terraform output
RDS_ENDPOINT=$(cd terraform && terraform output -raw rds_endpoint)

# Create secret
kubectl create secret generic database-secret \
    --from-literal=host=$RDS_ENDPOINT \
    --from-literal=database=taskdb \
    --from-literal=username=dbadmin \
    --from-literal=password=$DB_PASSWORD \
    -n task-manager
```

### Step 3: Build and Push Docker Images

```bash
# Set image tag
export IMAGE_TAG=v1.0.0

# Run build script
./scripts/build-and-push.sh
```

**Manual Build (if script fails)**:

```bash
# Get AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

# Login to ECR
aws ecr get-login-password --region $AWS_REGION | \
    docker login --username AWS --password-stdin $ECR_REGISTRY

# Build and push backend
cd backend
docker build -t $ECR_REGISTRY/production-task-manager-backend:$IMAGE_TAG .
docker push $ECR_REGISTRY/production-task-manager-backend:$IMAGE_TAG
cd ..

# Build and push frontend
cd frontend
docker build -t $ECR_REGISTRY/production-task-manager-frontend:$IMAGE_TAG .
docker push $ECR_REGISTRY/production-task-manager-frontend:$IMAGE_TAG
cd ..
```

### Step 4: Deploy Application to Kubernetes

```bash
./scripts/deploy-app.sh
```

**Manual Deployment**:

```bash
# Apply ConfigMaps
kubectl apply -f kubernetes/app/configmap.yaml

# Update deployment files with correct image tags
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

# Create temporary files with substitutions
sed "s|\${ECR_REGISTRY}|${ECR_REGISTRY}|g; s|\${IMAGE_TAG}|${IMAGE_TAG}|g" \
    kubernetes/app/backend-deployment.yaml | kubectl apply -f -

sed "s|\${ECR_REGISTRY}|${ECR_REGISTRY}|g; s|\${IMAGE_TAG}|${IMAGE_TAG}|g" \
    kubernetes/app/frontend-deployment.yaml | kubectl apply -f -

# Apply remaining resources
kubectl apply -f kubernetes/app/ingress.yaml
kubectl apply -f kubernetes/app/hpa.yaml
kubectl apply -f kubernetes/app/networkpolicy.yaml
kubectl apply -f kubernetes/monitoring/servicemonitor.yaml
```

### Step 5: Verify Deployment

```bash
# Check pod status
kubectl get pods -n task-manager

# Check services
kubectl get svc -n task-manager

# Check ingress
kubectl get ingress -n task-manager

# Wait for deployments to be ready
kubectl rollout status deployment/backend -n task-manager
kubectl rollout status deployment/frontend -n task-manager
```

### Step 6: Get Application URL

```bash
# Get ALB DNS name
kubectl get ingress task-manager-ingress -n task-manager \
    -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# Test the application
INGRESS_URL=$(kubectl get ingress task-manager-ingress -n task-manager \
    -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

curl http://$INGRESS_URL/health
```

## CI/CD Setup

### Option 1: Jenkins Setup

#### Step 1: Deploy Jenkins

```bash
cd jenkins
./setup-jenkins.sh
cd ..
```

#### Step 2: Access Jenkins

```bash
# Get Jenkins URL
JENKINS_URL=$(kubectl get svc jenkins -n jenkins \
    -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

echo "Jenkins URL: http://$JENKINS_URL/jenkins"

# Get initial admin password
kubectl exec -n jenkins -it \
    $(kubectl get pods -n jenkins -l app=jenkins -o jsonpath='{.items[0].metadata.name}') \
    -- cat /var/jenkins_home/secrets/initialAdminPassword
```

#### Step 3: Configure Jenkins

1. Access Jenkins at `http://<JENKINS_URL>/jenkins`
2. Enter the initial admin password
3. Install suggested plugins
4. Create admin user
5. Configure Jenkins URL

#### Step 4: Add Credentials

1. Go to **Manage Jenkins** → **Manage Credentials**
2. Add GitHub credentials:
   - Kind: Username with password
   - ID: `github-credentials`
   - Username: Your GitHub username
   - Password: GitHub personal access token

3. Add AWS credentials:
   - Kind: AWS Credentials
   - ID: `aws-credentials`
   - Access Key ID: Your AWS access key
   - Secret Access Key: Your AWS secret key

4. Add AWS Account ID:
   - Kind: Secret text
   - ID: `aws-account-id`
   - Secret: Your AWS account ID

#### Step 5: Create Pipeline Job

1. New Item → Pipeline
2. Name: `task-manager-pipeline`
3. Build Triggers: GitHub hook trigger for GITScm polling
4. Pipeline Definition: Pipeline script from SCM
5. SCM: Git
6. Repository URL: Your GitHub repo URL
7. Credentials: github-credentials
8. Branch: `*/main`
9. Script Path: `Jenkinsfile`

#### Step 6: Configure GitHub Webhook

1. Go to your GitHub repository settings
2. Webhooks → Add webhook
3. Payload URL: `http://<JENKINS_URL>/jenkins/github-webhook/`
4. Content type: application/json
5. Events: Just the push event
6. Active: ✓

### Option 2: GitHub Actions Setup

#### Step 1: Add GitHub Secrets

1. Go to repository Settings → Secrets and variables → Actions
2. Add the following secrets:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`

#### Step 2: Verify Workflow

The workflow file is already in `.github/workflows/ci.yml`. It will run automatically on push to main/develop branches.

## Monitoring Setup

### Access Grafana

```bash
# Get Grafana URL
kubectl get svc -n monitoring prometheus-grafana

# Get admin password
kubectl get secret -n monitoring prometheus-grafana \
    -o jsonpath='{.data.admin-password}' | base64 -d
echo

# Port forward (if using ClusterIP)
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
```

### Configure Dashboards

1. Access Grafana at `http://localhost:3000`
2. Login with admin/password
3. Dashboards are pre-configured and will auto-import

### Set Up Alerts

Alerts are configured in `kubernetes/monitoring/servicemonitor.yaml`:
- Backend High Error Rate
- Backend High Latency
- Backend Down
- High Memory/CPU Usage

Configure notification channels in Grafana:
1. Alerting → Notification channels
2. Add channel (Slack, Email, etc.)

## Post-Deployment Verification

### 1. Health Checks

```bash
# Backend health
kubectl exec -n task-manager \
    $(kubectl get pod -n task-manager -l app=backend -o jsonpath='{.items[0].metadata.name}') \
    -- wget -q -O- http://localhost:3000/health/ready

# Test API
INGRESS_URL=$(kubectl get ingress task-manager-ingress -n task-manager \
    -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

curl http://$INGRESS_URL/api/tasks
```

### 2. Create Test Data

```bash
# Create a test task
curl -X POST http://$INGRESS_URL/api/tasks \
    -H "Content-Type: application/json" \
    -d '{
        "title": "Test Task",
        "description": "This is a test task",
        "status": "pending",
        "priority": "high"
    }'

# Get all tasks
curl http://$INGRESS_URL/api/tasks
```

### 3. Monitor Logs

```bash
# Backend logs
kubectl logs -f -l app=backend -n task-manager

# Frontend logs
kubectl logs -f -l app=frontend -n task-manager

# All logs from namespace
kubectl logs -f --all-containers=true -n task-manager
```

### 4. Check Metrics

Access Prometheus:
```bash
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
```

Visit `http://localhost:9090` and run queries:
- `up{namespace="task-manager"}`
- `http_requests_total`
- `http_request_duration_seconds`

## Rollback Procedures

### Rollback Kubernetes Deployment

```bash
# View rollout history
kubectl rollout history deployment/backend -n task-manager
kubectl rollout history deployment/frontend -n task-manager

# Rollback to previous version
kubectl rollout undo deployment/backend -n task-manager
kubectl rollout undo deployment/frontend -n task-manager

# Rollback to specific revision
kubectl rollout undo deployment/backend -n task-manager --to-revision=2
```

### Rollback Infrastructure Changes

```bash
cd terraform

# View state
terraform show

# Restore from backup (if needed)
terraform state pull > backup.tfstate

# Revert to previous version
git checkout <previous-commit-hash>
terraform plan
terraform apply
```

### Emergency Procedures

#### Scale Down Application
```bash
kubectl scale deployment/backend -n task-manager --replicas=0
kubectl scale deployment/frontend -n task-manager --replicas=0
```

#### Database Rollback
```bash
# RDS automatically creates snapshots
# Restore from snapshot in AWS Console or CLI

aws rds restore-db-instance-from-db-snapshot \
    --db-instance-identifier devops-task-manager-db-restored \
    --db-snapshot-identifier <snapshot-id>
```

## Maintenance

### Update Application

```bash
# Build new version
export IMAGE_TAG=v1.1.0
./scripts/build-and-push.sh

# Deploy new version
./scripts/deploy-app.sh
```

### Update Kubernetes Version

```bash
# Update EKS cluster version
aws eks update-cluster-version \
    --name $CLUSTER_NAME \
    --kubernetes-version 1.30

# Update node groups
aws eks update-nodegroup-version \
    --cluster-name $CLUSTER_NAME \
    --nodegroup-name devops-task-manager-general
```

### Backup Database

```bash
# Create manual snapshot
aws rds create-db-snapshot \
    --db-instance-identifier devops-task-manager-db \
    --db-snapshot-identifier manual-snapshot-$(date +%Y%m%d-%H%M%S)
```

## Troubleshooting

See main README.md for detailed troubleshooting steps.

## Next Steps

- [ ] Configure custom domain and SSL certificate
- [ ] Set up CloudWatch alarms
- [ ] Configure automated backups
- [ ] Implement disaster recovery plan
- [ ] Set up multi-region deployment
- [ ] Configure WAF for additional security
- [ ] Implement cost optimization strategies

