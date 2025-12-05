# Architecture Documentation

## System Architecture

### Overview

The DevOps Task Manager is a cloud-native application built on AWS using modern DevOps practices, containerization, and Infrastructure as Code.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                              Internet                                    │
└────────────────────────────┬────────────────────────────────────────────┘
                             │
                             ▼
                    ┌────────────────┐
                    │  Route 53 DNS  │
                    │   (Optional)   │
                    └────────┬───────┘
                             │
                             ▼
┌────────────────────────────────────────────────────────────────────────┐
│                          AWS Cloud                                      │
│                                                                          │
│  ┌────────────────────────────────────────────────────────────────┐   │
│  │                    Application Load Balancer                    │   │
│  │                    (Internet-facing)                            │   │
│  └────────────────────────┬───────────────────────────────────────┘   │
│                            │                                             │
│  ┌─────────────────────── VPC (10.0.0.0/16) ────────────────────────┐ │
│  │                                                                    │ │
│  │  ┌──────────── Public Subnets (3 AZs) ──────────────┐          │ │
│  │  │                                                    │          │ │
│  │  │  ┌─────────────┐  ┌─────────────┐  ┌──────────┐│          │ │
│  │  │  │NAT Gateway  │  │NAT Gateway  │  │NAT GW    ││          │ │
│  │  │  │   AZ-1      │  │   AZ-2      │  │  AZ-3    ││          │ │
│  │  │  └─────────────┘  └─────────────┘  └──────────┘│          │ │
│  │  └────────────────────────────────────────────────┘          │ │
│  │                            │                                   │ │
│  │  ┌──────────── Private Subnets (3 AZs) ──────────────┐       │ │
│  │  │                                                     │       │ │
│  │  │         ┌────────── EKS Cluster ──────────┐       │       │ │
│  │  │         │                                  │       │       │ │
│  │  │         │  ┌─────────────────────┐        │       │       │ │
│  │  │         │  │  task-manager NS    │        │       │       │ │
│  │  │         │  │  ┌───────────────┐  │        │       │       │ │
│  │  │         │  │  │   Frontend    │  │        │       │       │ │
│  │  │         │  │  │  Deployment   │  │        │       │       │ │
│  │  │         │  │  │  - 3 Replicas │  │        │       │       │ │
│  │  │         │  │  │  - React/Nginx│  │        │       │       │ │
│  │  │         │  │  └───────────────┘  │        │       │       │ │
│  │  │         │  │  ┌───────────────┐  │        │       │       │ │
│  │  │         │  │  │   Backend     │  │        │       │       │ │
│  │  │         │  │  │  Deployment   │  │        │       │       │ │
│  │  │         │  │  │  - 3 Replicas │  │        │       │       │ │
│  │  │         │  │  │  - Node.js    │  │        │       │       │ │
│  │  │         │  │  └───────────────┘  │        │       │       │ │
│  │  │         │  └─────────────────────┘        │       │       │ │
│  │  │         │                                  │       │       │ │
│  │  │         │  ┌─────────────────────┐        │       │       │ │
│  │  │         │  │   monitoring NS     │        │       │       │ │
│  │  │         │  │  - Prometheus       │        │       │       │ │
│  │  │         │  │  - Grafana          │        │       │       │ │
│  │  │         │  │  - AlertManager     │        │       │       │ │
│  │  │         │  └─────────────────────┘        │       │       │ │
│  │  │         │                                  │       │       │ │
│  │  │         │  ┌─────────────────────┐        │       │       │ │
│  │  │         │  │    jenkins NS       │        │       │       │ │
│  │  │         │  │  - Jenkins Master   │        │       │       │ │
│  │  │         │  └─────────────────────┘        │       │       │ │
│  │  │         └──────────────────────────────────┘       │       │ │
│  │  └─────────────────────────────────────────────────────┘       │ │
│  │                            │                                     │ │
│  │  ┌──────────── Database Subnets (3 AZs) ───────────┐           │ │
│  │  │                                                   │           │ │
│  │  │  ┌──────────────────┐  ┌──────────────────┐    │           │ │
│  │  │  │  RDS Primary     │  │  RDS Standby     │    │           │ │
│  │  │  │  PostgreSQL 15   │──│  (Multi-AZ)      │    │           │ │
│  │  │  │  AZ-1            │  │  AZ-2            │    │           │ │
│  │  │  └──────────────────┘  └──────────────────┘    │           │ │
│  │  └───────────────────────────────────────────────────┘           │ │
│  └────────────────────────────────────────────────────────────────┘ │
│                                                                        │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐               │
│  │     ECR      │  │      S3      │  │  CloudWatch  │               │
│  │ - Backend    │  │  - Assets    │  │   - Logs     │               │
│  │ - Frontend   │  │  - Backups   │  │   - Metrics  │               │
│  └──────────────┘  └──────────────┘  └──────────────┘               │
└────────────────────────────────────────────────────────────────────────┘

                                 ▲
                                 │
                                 │
                        ┌────────┴────────┐
                        │   CI/CD Flow    │
                        │                 │
                        │  GitHub         │
                        │     ↓           │
                        │  Jenkins        │
                        │     ↓           │
                        │  Build/Test     │
                        │     ↓           │
                        │  ECR Push       │
                        │     ↓           │
                        │  K8s Deploy     │
                        └─────────────────┘
```

## Component Details

### 1. Networking Layer

#### VPC Design
- **CIDR**: 10.0.0.0/16
- **Availability Zones**: 3 for high availability
- **Subnet Strategy**:
  - Public Subnets (10.0.0.0/20 - 10.0.32.0/20): Internet-facing resources
  - Private Subnets (10.0.64.0/20 - 10.0.96.0/20): Application workloads
  - Database Subnets (10.0.128.0/20 - 10.0.160.0/20): Database instances

#### Load Balancing
- **ALB (Application Load Balancer)**:
  - Internet-facing
  - Distributes traffic across frontend pods
  - SSL termination (optional with ACM)
  - Path-based routing (/api → backend, / → frontend)

#### NAT Strategy
- NAT Gateway in each AZ for high availability
- Enables outbound internet access for private subnets
- Eliminates single point of failure

### 2. Compute Layer

#### EKS Cluster
- **Version**: 1.29 (latest stable)
- **Node Groups**:
  - Type: Managed node groups
  - Instance Type: t3.medium (configurable)
  - Scaling: 2-5 nodes with autoscaling
  - Capacity: On-Demand (configurable to Spot)

#### Pod Architecture
- **Frontend Pods**:
  - Replicas: 3 (for HA)
  - Resources: 128Mi-256Mi memory, 100m-200m CPU
  - Image: Nginx serving React SPA
  - Anti-affinity: Spread across nodes

- **Backend Pods**:
  - Replicas: 3 (for HA)
  - Resources: 256Mi-512Mi memory, 250m-500m CPU
  - Image: Node.js 18 Express API
  - Anti-affinity: Spread across nodes

#### Autoscaling
- **HPA (Horizontal Pod Autoscaler)**:
  - CPU threshold: 70%
  - Memory threshold: 80%
  - Scale up: Fast (30s stabilization)
  - Scale down: Conservative (300s stabilization)

- **Cluster Autoscaler**:
  - Automatically adjusts node count
  - Based on pending pods
  - Integrated with AWS Auto Scaling Groups

### 3. Data Layer

#### RDS PostgreSQL
- **Version**: 15.5
- **Configuration**:
  - Instance Class: db.t3.micro (configurable)
  - Multi-AZ: Enabled (automatic failover)
  - Storage: 20GB GP3 with autoscaling
  - Encryption: KMS encryption at rest

- **Backup Strategy**:
  - Automated backups: 7-day retention
  - Backup window: 03:00-04:00 UTC
  - Maintenance window: Monday 04:00-05:00 UTC
  - Final snapshot on deletion

- **Performance**:
  - Enhanced monitoring enabled
  - Performance Insights enabled
  - CloudWatch logs integration

### 4. Container Registry

#### ECR (Elastic Container Registry)
- **Repositories**:
  - production-task-manager-backend
  - production-task-manager-frontend

- **Features**:
  - Image scanning on push
  - Lifecycle policies (keep last 10 tagged images)
  - Encryption at rest
  - Cross-region replication (optional)

### 5. Monitoring & Observability

#### Prometheus Stack
- **Components**:
  - Prometheus Server: Metrics collection
  - AlertManager: Alert routing
  - Grafana: Visualization
  - Node Exporter: Node metrics
  - Kube State Metrics: K8s object metrics

- **Metrics**:
  - Application metrics (/metrics endpoint)
  - Infrastructure metrics
  - Business metrics
  - Custom metrics via client libraries

#### Grafana Dashboards
- Kubernetes cluster overview
- Node metrics
- Pod metrics
- Application-specific dashboards

#### Alerting
- High error rates
- High latency
- Pod/service down
- Resource exhaustion
- Database connectivity issues

### 6. CI/CD Pipeline

#### Jenkins Pipeline
1. **Source Stage**:
   - GitHub webhook triggers build
   - Checkout code from repository

2. **Test Stage**:
   - Run unit tests (backend & frontend)
   - Run linters
   - Code quality checks

3. **Build Stage**:
   - Build Docker images
   - Multi-stage builds for optimization
   - Tag with build number and git hash

4. **Security Stage**:
   - Container image scanning (Trivy)
   - Vulnerability assessment
   - Fail on critical vulnerabilities

5. **Push Stage**:
   - Login to ECR
   - Push images with tags
   - Latest and version tags

6. **Deploy Stage**:
   - Update Kubernetes manifests
   - Apply to EKS cluster
   - Rolling update strategy

7. **Verify Stage**:
   - Health checks
   - Smoke tests
   - Rollback on failure

#### GitHub Actions (Alternative)
- Parallel to Jenkins
- Runs on push to main/develop
- Similar stages with GitHub-native features

### 7. Security Architecture

#### Network Security
- **Security Groups**:
  - EKS nodes: Restricted to necessary ports
  - RDS: Only accessible from EKS nodes
  - ALB: Public HTTP/HTTPS only

- **Network Policies**:
  - Pod-to-pod communication rules
  - Namespace isolation
  - Egress controls

#### Identity & Access
- **IAM Roles**:
  - EKS cluster role
  - Node group role
  - Service account roles (IRSA)
  - Least privilege principle

- **RBAC**:
  - Namespace-level permissions
  - Service account bindings
  - Role separation

#### Data Protection
- **Encryption at Rest**:
  - RDS: KMS encryption
  - EKS secrets: KMS encryption
  - S3: Server-side encryption

- **Encryption in Transit**:
  - TLS for all external communication
  - Internal service mesh (future enhancement)

### 8. High Availability

#### Multi-AZ Deployment
- Resources distributed across 3 AZs
- Database multi-AZ automatic failover
- NAT Gateways in each AZ

#### Pod Distribution
- Anti-affinity rules
- Spread across nodes and AZs
- PodDisruptionBudgets

#### Self-Healing
- Liveness probes
- Readiness probes
- Automatic pod restart
- Node auto-replacement

### 9. Scalability

#### Horizontal Scaling
- HPA for pods
- Cluster autoscaler for nodes
- Database read replicas (future)

#### Performance Optimization
- CDN for static assets (future)
- Connection pooling
- Caching layer (Redis - future)
- Efficient queries with indexes

## Data Flow

### Request Flow
1. User → DNS (optional) → ALB
2. ALB → Frontend Service → Frontend Pods
3. Frontend → ALB → Backend Service → Backend Pods
4. Backend → RDS PostgreSQL

### CI/CD Flow
1. Developer pushes code to GitHub
2. GitHub webhook triggers Jenkins
3. Jenkins runs tests and builds
4. Images pushed to ECR
5. Jenkins updates K8s manifests
6. Rolling deployment to EKS
7. Health checks verify deployment

### Monitoring Flow
1. Pods expose /metrics endpoint
2. Prometheus scrapes metrics
3. Metrics stored in Prometheus TSDB
4. Grafana queries Prometheus
5. Alerts sent to AlertManager
6. Notifications to configured channels

## Disaster Recovery

### Backup Strategy
- **Database**: Daily automated backups
- **Configuration**: Terraform state in S3
- **Code**: Git repository
- **Secrets**: AWS Secrets Manager (future)

### Recovery Procedures
- RDS point-in-time recovery
- Infrastructure recreation via Terraform
- Application redeployment via CI/CD
- Kubernetes state in etcd (EKS managed)

## Cost Optimization

### Current Optimizations
- Right-sized instance types
- Autoscaling reduces idle resources
- GP3 storage (cost-effective)
- Lifecycle policies for ECR

### Future Optimizations
- Spot instances for non-critical workloads
- Reserved instances for predictable load
- S3 lifecycle policies
- CloudWatch log retention policies

## Performance Characteristics

### Expected Metrics
- **Latency**: 
  - Frontend: <100ms
  - Backend API: <200ms
  - Database: <50ms

- **Throughput**:
  - 1000+ requests/second (current setup)
  - Horizontal scaling for higher loads

- **Availability**:
  - Target: 99.9% uptime
  - Multi-AZ for redundancy
  - Automatic failover

## Future Enhancements

1. **Multi-Region Deployment**
   - Active-active setup
   - Global load balancing
   - Cross-region replication

2. **Service Mesh**
   - Istio or Linkerd
   - Advanced traffic management
   - mTLS between services

3. **Caching Layer**
   - Redis for session/data caching
   - Reduces database load
   - Improves response times

4. **CDN Integration**
   - CloudFront for static assets
   - Edge caching
   - Lower latency globally

5. **Advanced Security**
   - WAF (Web Application Firewall)
   - DDoS protection
   - Runtime security scanning

6. **Observability**
   - Distributed tracing (Jaeger)
   - Log aggregation (ELK/EFK)
   - APM integration

7. **GitOps**
   - ArgoCD or Flux
   - Declarative deployments
   - Drift detection

