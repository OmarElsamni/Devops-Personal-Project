#!/bin/bash
# Setup Jenkins on Kubernetes

set -e

echo "Setting up Jenkins on Kubernetes..."

# Apply Jenkins deployment
kubectl apply -f jenkins/jenkins-deployment.yaml

# Wait for Jenkins to be ready
echo "Waiting for Jenkins to be ready..."
kubectl wait --for=condition=ready pod -l app=jenkins -n jenkins --timeout=600s

# Get Jenkins initial admin password
echo ""
echo "========================================"
echo "Jenkins is ready!"
echo "========================================"
echo ""
echo "Get Jenkins URL:"
kubectl get svc jenkins -n jenkins

echo ""
echo "Get initial admin password:"
echo "kubectl exec -n jenkins -it \$(kubectl get pods -n jenkins -l app=jenkins -o jsonpath='{.items[0].metadata.name}') -- cat /var/jenkins_home/secrets/initialAdminPassword"

echo ""
echo "Access Jenkins at: http://<LOAD_BALANCER_IP>/jenkins"
echo ""
echo "After login, configure Jenkins with:"
echo "1. Install suggested plugins"
echo "2. Create admin user"
echo "3. Configure GitHub webhook"
echo "4. Add AWS credentials"
echo "5. Create pipeline job using the Jenkinsfile"

