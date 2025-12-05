#!/bin/bash
# Install AWS Load Balancer Controller for EKS

set -e

CLUSTER_NAME=${1:-devops-task-manager}
AWS_REGION=${2:-us-east-1}
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo "Installing AWS Load Balancer Controller for cluster: $CLUSTER_NAME in region: $AWS_REGION"

# Create IAM OIDC provider for cluster
echo "Creating IAM OIDC provider..."
eksctl utils associate-iam-oidc-provider \
    --region $AWS_REGION \
    --cluster $CLUSTER_NAME \
    --approve

# Download IAM policy
echo "Downloading IAM policy..."
curl -o iam_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.7.0/docs/install/iam_policy.json

# Create IAM policy
echo "Creating IAM policy..."
aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam_policy.json \
    --region $AWS_REGION || echo "Policy already exists"

# Create IAM service account
echo "Creating IAM service account..."
eksctl create iamserviceaccount \
    --cluster=$CLUSTER_NAME \
    --namespace=kube-system \
    --name=aws-load-balancer-controller \
    --attach-policy-arn=arn:aws:iam::${AWS_ACCOUNT_ID}:policy/AWSLoadBalancerControllerIAMPolicy \
    --override-existing-serviceaccounts \
    --region $AWS_REGION \
    --approve

# Add EKS chart repo
echo "Adding EKS Helm chart repository..."
helm repo add eks https://aws.github.io/eks-charts
helm repo update

# Install AWS Load Balancer Controller
echo "Installing AWS Load Balancer Controller..."
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
    -n kube-system \
    --set clusterName=$CLUSTER_NAME \
    --set serviceAccount.create=false \
    --set serviceAccount.name=aws-load-balancer-controller \
    --set region=$AWS_REGION \
    --set vpcId=$(aws eks describe-cluster --name $CLUSTER_NAME --region $AWS_REGION --query "cluster.resourcesVpcConfig.vpcId" --output text)

echo "AWS Load Balancer Controller installation complete!"
echo "Verify installation with: kubectl get deployment -n kube-system aws-load-balancer-controller"

# Cleanup
rm -f iam_policy.json

