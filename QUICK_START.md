# Quick Start Guide

Get your DevOps Task Manager up and running in minutes!

## Prerequisites Check

Run this command to verify all tools are installed:

```bash
command -v aws && command -v terraform && command -v kubectl && command -v helm && command -v docker && echo "✅ All tools installed!" || echo "❌ Missing tools"
```

## Installation Steps

### 1. AWS Configuration (2 minutes)

```bash
aws configure
# Enter your credentials when prompted
```

### 2. Set Environment Variables (1 minute)

```bash
export AWS_REGION=us-east-1
export CLUSTER_NAME=devops-task-manager
export DB_PASSWORD=$(openssl rand -base64 32)

# Save password (IMPORTANT!)
echo "DB Password: $DB_PASSWORD" > SAVE_THIS_PASSWORD.txt
chmod 600 SAVE_THIS_PASSWORD.txt
```

### 3. Make Scripts Executable (30 seconds)

```bash
find . -type f -name "*.sh" -exec chmod +x {} \;
```

### 4. Deploy Infrastructure (15-20 minutes)

```bash
./scripts/setup-infrastructure.sh
```

This single script:
- ✅ Creates S3 bucket for Terraform state
- ✅ Deploys VPC, EKS, RDS with Terraform
- ✅ Configures kubectl
- ✅ Installs AWS Load Balancer Controller
- ✅ Installs Metrics Server
- ✅ Deploys Prometheus & Grafana
- ✅ Optionally installs Jenkins

### 5. Build & Push Images (5 minutes)

```bash
export IMAGE_TAG=v1.0.0
./scripts/build-and-push.sh
```

### 6. Deploy Application (3 minutes)

```bash
./scripts/deploy-app.sh
```

### 7. Access Your Application (1 minute)

```bash
# Get the URL
kubectl get ingress -n task-manager

# Or use this command
INGRESS_URL=$(kubectl get ingress task-manager-ingress -n task-manager -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "Application URL: http://$INGRESS_URL"
```

## Verify Everything Works

### Check Pods
```bash
kubectl get pods -n task-manager
# Should show 3 backend and 3 frontend pods RUNNING
```

### Test Backend API
```bash
INGRESS_URL=$(kubectl get ingress task-manager-ingress -n task-manager -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
curl http://$INGRESS_URL/api/tasks
```

### Access Grafana
```bash
kubectl get svc -n monitoring prometheus-grafana
kubectl get secret -n monitoring prometheus-grafana -o jsonpath='{.data.admin-password}' | base64 -d
echo
```

## Access URLs

After deployment, you'll have:

1. **Application**: `http://<ALB-DNS-NAME>`
2. **API**: `http://<ALB-DNS-NAME>/api`
3. **Grafana**: Get service endpoint with `kubectl get svc -n monitoring`
4. **Jenkins** (if installed): Get service endpoint with `kubectl get svc -n jenkins`

## Local Development

Want to develop locally? Use Docker Compose:

```bash
docker-compose up -d
```

Access:
- Frontend: http://localhost:8080
- Backend: http://localhost:3000
- Grafana: http://localhost:3001
- Prometheus: http://localhost:9090

## Common Commands

### View Logs
```bash
# Backend logs
kubectl logs -f -l app=backend -n task-manager

# Frontend logs
kubectl logs -f -l app=frontend -n task-manager
```

### Scale Application
```bash
# Scale backend to 5 replicas
kubectl scale deployment/backend -n task-manager --replicas=5
```

### Restart Deployment
```bash
kubectl rollout restart deployment/backend -n task-manager
```

### Update Application
```bash
# Build new version
export IMAGE_TAG=v1.1.0
./scripts/build-and-push.sh

# Deploy
./scripts/deploy-app.sh
```

## Cleanup

When you're done:

```bash
./scripts/cleanup.sh
```

**Warning**: This deletes everything!

## Troubleshooting

### Pods not starting?
```bash
kubectl describe pod <pod-name> -n task-manager
```

### Can't access application?
```bash
# Check ingress
kubectl get ingress -n task-manager
kubectl describe ingress task-manager-ingress -n task-manager

# Check services
kubectl get svc -n task-manager
```

### Database connection issues?
```bash
# Check secret
kubectl get secret database-secret -n task-manager -o yaml

# Check RDS endpoint
cd terraform && terraform output rds_endpoint
```

## Next Steps

1. ✅ Set up CI/CD with Jenkins or GitHub Actions
2. ✅ Configure custom domain and SSL
3. ✅ Set up CloudWatch alarms
4. ✅ Configure automated backups
5. ✅ Review monitoring dashboards in Grafana

## Support

- 📖 Full docs: See `README.md`
- 🚀 Deployment guide: See `DEPLOYMENT_GUIDE.md`
- 🏗️ Architecture: See `ARCHITECTURE.md`

## Estimated Costs

Running this infrastructure 24/7:

- **EKS Cluster**: ~$73/month
- **EC2 Nodes** (3 x t3.medium): ~$90/month
- **RDS** (db.t3.micro Multi-AZ): ~$30/month
- **ALB**: ~$23/month
- **NAT Gateways** (3): ~$100/month
- **Data Transfer**: Variable
- **Total**: ~$316/month

💡 **Cost Savings**:
- Use t3.small nodes: Save ~$30/month
- Single NAT Gateway: Save ~$65/month
- RDS Single-AZ: Save ~$15/month
- Spot instances: Save ~40% on EC2

## Success Checklist

- [ ] All prerequisites installed
- [ ] AWS credentials configured
- [ ] Infrastructure deployed (EKS, RDS, VPC)
- [ ] Docker images built and pushed to ECR
- [ ] Application deployed to Kubernetes
- [ ] Application accessible via ALB
- [ ] Monitoring stack running (Prometheus/Grafana)
- [ ] CI/CD configured (Jenkins or GitHub Actions)
- [ ] Passwords and credentials saved securely

**Congratulations! You now have a production-ready DevOps infrastructure! 🎉**

