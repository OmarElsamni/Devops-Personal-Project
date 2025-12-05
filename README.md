# DevOps Task Manager - Production-Ready Project

A comprehensive DevOps project demonstrating modern infrastructure and CI/CD practices with a full-stack Task Management application deployed on AWS EKS.

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         AWS Cloud                                │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                    VPC (10.0.0.0/16)                      │  │
│  │                                                            │  │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │  │
│  │  │ Public Subnet│  │ Public Subnet│  │ Public Subnet│   │  │
│  │  │  (AZ-1)      │  │  (AZ-2)      │  │  (AZ-3)      │   │  │
│  │  │              │  │              │  │              │   │  │
│  │  │  NAT Gateway │  │  NAT Gateway │  │  NAT Gateway │   │  │
│  │  │      ALB     │  │              │  │              │   │  │
│  │  └──────────────┘  └──────────────┘  └──────────────┘   │  │
│  │                                                            │  │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │  │
│  │  │Private Subnet│  │Private Subnet│  │Private Subnet│   │  │
│  │  │              │  │              │  │              │   │  │
│  │  │  EKS Nodes   │  │  EKS Nodes   │  │  EKS Nodes   │   │  │
│  │  │  - Frontend  │  │  - Frontend  │  │  - Frontend  │   │  │
│  │  │  - Backend   │  │  - Backend   │  │  - Backend   │   │  │
│  │  │  - Monitoring│  │  - Monitoring│  │  - Monitoring│   │  │
│  │  └──────────────┘  └──────────────┘  └──────────────┘   │  │
│  │                                                            │  │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │  │
│  │  │  DB Subnet   │  │  DB Subnet   │  │  DB Subnet   │   │  │
│  │  │              │  │              │  │              │   │  │
│  │  │ RDS (Primary)│  │ RDS (Standby)│  │              │   │  │
│  │  └──────────────┘  └──────────────┘  └──────────────┘   │  │
│  └────────────────────────────────────────────────────────────┘  │
│                                                                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │     ECR      │  │      S3      │  │  CloudWatch  │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
└───────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                      CI/CD Pipeline                              │
│                                                                   │
│  GitHub → Jenkins → Build → Test → ECR → Deploy → EKS          │
│                                                                   │
└───────────────────────────────────────────────────────────────────┘
```

## 📋 Project Components

### Application Stack
- **Frontend**: React 18 with TypeScript
- **Backend**: Node.js 18 with Express
- **Database**: PostgreSQL 15 (AWS RDS)
- **Container Runtime**: Docker

### Infrastructure
- **Cloud Provider**: AWS
- **Container Orchestration**: Amazon EKS (Kubernetes 1.29)
- **Infrastructure as Code**: Terraform 1.6+
- **Networking**: VPC with public/private subnets across 3 AZs
- **Load Balancing**: AWS Application Load Balancer

### CI/CD
- **Primary**: Jenkins on Kubernetes
- **Alternative**: GitHub Actions
- **Container Registry**: Amazon ECR
- **Deployment Strategy**: Rolling updates with zero downtime

### Monitoring & Observability
- **Metrics**: Prometheus
- **Visualization**: Grafana
- **Logging**: CloudWatch Logs
- **Alerting**: Prometheus AlertManager

## 🚀 Quick Start

### Prerequisites

Install the following tools:
- AWS CLI (v2.x)
- Terraform (v1.6+)
- kubectl (v1.29+)
- Helm (v3.12+)
- Docker (v24+)
- eksctl (v0.165+)

### Step 1: Configure AWS Credentials

```bash
aws configure
# Enter your AWS Access Key ID
# Enter your AWS Secret Access Key
# Default region: us-east-1
# Default output format: json
```

### Step 2: Clone the Repository

```bash
git clone <your-repo-url>
cd "Personal Devops Project"
```

### Step 3: Setup Infrastructure

```bash
# Make scripts executable
chmod +x scripts/*.sh
chmod +x kubernetes/aws-load-balancer-controller/install.sh
chmod +x kubernetes/metrics-server/install.sh
chmod +x jenkins/setup-jenkins.sh

# Run infrastructure setup
./scripts/setup-infrastructure.sh
```

This script will:
1. Create S3 bucket for Terraform state
2. Create DynamoDB table for state locking
3. Deploy VPC, EKS cluster, RDS database
4. Configure kubectl
5. Install AWS Load Balancer Controller
6. Install Metrics Server
7. Setup Prometheus & Grafana
8. Optionally install Jenkins

### Step 4: Build and Push Docker Images

```bash
export AWS_REGION=us-east-1
export IMAGE_TAG=v1.0.0

./scripts/build-and-push.sh
```

### Step 5: Deploy Application

```bash
./scripts/deploy-app.sh
```

### Step 6: Access Your Application

```bash
# Get the application URL
kubectl get ingress -n task-manager

# Access the application
open http://<ALB-DNS-NAME>
```

## 📁 Project Structure

```
.
├── backend/                    # Backend application
│   ├── src/
│   │   ├── config/            # Database configuration
│   │   ├── routes/            # API routes
│   │   ├── middleware/        # Express middleware
│   │   └── server.js          # Entry point
│   ├── Dockerfile
│   └── package.json
│
├── frontend/                   # Frontend application
│   ├── src/
│   │   ├── components/        # React components
│   │   ├── services/          # API services
│   │   ├── App.tsx
│   │   └── index.tsx
│   ├── Dockerfile
│   ├── nginx.conf
│   └── package.json
│
├── terraform/                  # Infrastructure as Code
│   ├── modules/
│   │   ├── vpc/               # VPC module
│   │   ├── eks/               # EKS cluster module
│   │   ├── rds/               # RDS database module
│   │   └── ecr/               # ECR repositories module
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
│
├── kubernetes/                 # Kubernetes manifests
│   ├── app/                   # Application deployments
│   │   ├── backend-deployment.yaml
│   │   ├── frontend-deployment.yaml
│   │   ├── ingress.yaml
│   │   ├── hpa.yaml
│   │   └── networkpolicy.yaml
│   ├── monitoring/            # Monitoring stack
│   │   ├── prometheus-values.yaml
│   │   └── servicemonitor.yaml
│   └── namespaces/
│       └── namespaces.yaml
│
├── jenkins/                    # Jenkins CI/CD
│   ├── jenkins-deployment.yaml
│   ├── jenkins-config.yaml
│   ├── plugins.txt
│   └── setup-jenkins.sh
│
├── scripts/                    # Automation scripts
│   ├── setup-infrastructure.sh
│   ├── deploy-app.sh
│   ├── build-and-push.sh
│   └── cleanup.sh
│
├── .github/workflows/         # GitHub Actions
│   └── ci.yml
│
├── Jenkinsfile                # Jenkins pipeline
└── README.md
```

## 🔧 Configuration

### Environment Variables

#### Backend
```env
NODE_ENV=production
PORT=3000
DB_HOST=<rds-endpoint>
DB_PORT=5432
DB_NAME=taskdb
DB_USER=dbadmin
DB_PASSWORD=<your-password>
```

#### Frontend
```env
REACT_APP_API_URL=http://<backend-url>/api
```

### Terraform Variables

Edit `terraform/variables.tf` or create `terraform.tfvars`:

```hcl
aws_region         = "us-east-1"
cluster_name       = "devops-task-manager"
cluster_version    = "1.29"
environment        = "production"

node_groups = {
  general = {
    desired_size   = 3
    min_size       = 2
    max_size       = 5
    instance_types = ["t3.medium"]
    capacity_type  = "ON_DEMAND"
    disk_size      = 20
  }
}

db_instance_class  = "db.t3.micro"
db_allocated_storage = 20
```

## 🔄 CI/CD Pipeline

### Jenkins Pipeline Flow

1. **Checkout**: Clone repository from GitHub
2. **Test**: Run unit tests for backend and frontend
3. **Build**: Build Docker images
4. **Security Scan**: Scan images with Trivy
5. **Push**: Push images to ECR
6. **Deploy**: Deploy to Kubernetes
7. **Verify**: Health checks and rollout verification

### Triggering a Pipeline

**Option 1: Jenkins**
- Push code to GitHub
- Jenkins webhook automatically triggers build
- Or manually trigger from Jenkins UI

**Option 2: GitHub Actions**
- Push to `main` branch
- GitHub Actions automatically runs CI/CD

## 📊 Monitoring

### Access Grafana

```bash
# Get Grafana URL
kubectl get svc -n monitoring prometheus-grafana

# Get Grafana password
kubectl get secret -n monitoring prometheus-grafana \
  -o jsonpath='{.data.admin-password}' | base64 -d
echo

# Port forward (if LoadBalancer not available)
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
```

Default credentials:
- Username: `admin`
- Password: Run the command above

### Pre-configured Dashboards

1. **Kubernetes Cluster Overview** (ID: 7249)
2. **Node Exporter** (ID: 1860)
3. **Pods Monitoring** (ID: 6417)

### Custom Alerts

Configured in `kubernetes/monitoring/servicemonitor.yaml`:
- High error rate (>5%)
- High latency (>2s)
- Service down
- High memory/CPU usage

## 🔐 Security Best Practices

### Implemented Security Features

1. **Network Security**
   - VPC with private subnets for workloads
   - Network policies for pod-to-pod communication
   - Security groups with least privilege

2. **Container Security**
   - Non-root containers
   - Read-only root filesystem
   - Resource limits and requests
   - Image vulnerability scanning

3. **Data Security**
   - RDS encryption at rest (KMS)
   - EKS secrets encryption
   - TLS in transit
   - Encrypted S3 buckets

4. **Access Control**
   - RBAC for Kubernetes
   - IAM roles for service accounts (IRSA)
   - Pod security policies
   - Least privilege IAM policies

## 📈 Scaling

### Horizontal Pod Autoscaling

HPA is configured for both frontend and backend:

```yaml
minReplicas: 3
maxReplicas: 10
targetCPUUtilization: 70%
targetMemoryUtilization: 80%
```

### Cluster Autoscaling

EKS node groups support autoscaling:

```hcl
min_size     = 2
max_size     = 5
desired_size = 3
```

## 🧪 Testing

### Backend Tests
```bash
cd backend
npm install
npm test
npm run lint
```

### Frontend Tests
```bash
cd frontend
npm install
npm test -- --watchAll=false
npm run lint
```

### Integration Tests
```bash
# Test backend health
kubectl exec -n task-manager <backend-pod> -- \
  wget -q -O- http://localhost:3000/health/ready

# Test database connection
kubectl exec -n task-manager <backend-pod> -- \
  wget -q -O- http://localhost:3000/health/ready
```

## 🐛 Troubleshooting

### Check Pod Status
```bash
kubectl get pods -n task-manager
kubectl describe pod <pod-name> -n task-manager
kubectl logs -f <pod-name> -n task-manager
```

### Check Service Endpoints
```bash
kubectl get endpoints -n task-manager
```

### Check Ingress
```bash
kubectl describe ingress task-manager-ingress -n task-manager
```

### Database Connection Issues
```bash
# Check database secret
kubectl get secret database-secret -n task-manager -o yaml

# Test connection from pod
kubectl exec -it <backend-pod> -n task-manager -- sh
# Inside pod:
psql -h $DB_HOST -U $DB_USER -d $DB_NAME
```

### View Application Logs
```bash
# Backend logs
kubectl logs -f deployment/backend -n task-manager

# Frontend logs
kubectl logs -f deployment/frontend -n task-manager

# All logs
kubectl logs -f -l app=backend -n task-manager --all-containers=true
```

## 🧹 Cleanup

To destroy all resources:

```bash
./scripts/cleanup.sh
```

**Warning**: This will delete:
- EKS cluster and all workloads
- RDS database (with final snapshot)
- VPC and networking resources
- ECR repositories
- S3 buckets (optional)

## 📚 Additional Resources

### AWS Documentation
- [Amazon EKS](https://docs.aws.amazon.com/eks/)
- [Amazon RDS](https://docs.aws.amazon.com/rds/)
- [AWS VPC](https://docs.aws.amazon.com/vpc/)

### Kubernetes
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Helm Documentation](https://helm.sh/docs/)

### Monitoring
- [Prometheus](https://prometheus.io/docs/)
- [Grafana](https://grafana.com/docs/)

### CI/CD
- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [GitHub Actions](https://docs.github.com/en/actions)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License.

## 👥 Authors

Your Name - DevOps Engineer

## 🙏 Acknowledgments

- AWS for cloud infrastructure
- Kubernetes community
- Prometheus & Grafana teams
- Jenkins community

