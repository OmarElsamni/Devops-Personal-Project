# GitHub Setup Guide

This guide will help you push this DevOps project to your GitHub account.

## Option 1: Automated Setup (Recommended)

### Step 1: Run the Setup Script

```bash
chmod +x setup-git.sh
./setup-git.sh
```

The script will:
- Initialize git repository
- Add all files
- Create initial commit
- Set up remote origin
- Provide next steps

### Step 2: Create GitHub Repository

1. Go to [https://github.com/new](https://github.com/new)
2. Enter repository name: `devops-task-manager` (or your choice)
3. **IMPORTANT**: Do NOT initialize with README, .gitignore, or license
4. Click "Create repository"

### Step 3: Push to GitHub

```bash
git push -u origin main
```

If you have 2FA enabled, you'll need a Personal Access Token:
1. Go to [GitHub Settings → Developer settings → Personal access tokens](https://github.com/settings/tokens)
2. Generate new token (classic)
3. Select scopes: `repo` (all)
4. Use token as password when pushing

## Option 2: Manual Setup

### Step 1: Initialize Git Repository

```bash
cd "/Users/omarelsamni/Personal Devops Project"
git init
```

### Step 2: Add Files

```bash
git add .
```

### Step 3: Create Initial Commit

```bash
git commit -m "Initial commit: Complete DevOps Task Manager project

- Full-stack application (React + Node.js + PostgreSQL)
- Terraform infrastructure for AWS EKS
- Kubernetes manifests and Helm charts
- CI/CD pipelines (Jenkins + GitHub Actions)
- Prometheus and Grafana monitoring
- Comprehensive documentation
- Automation scripts for deployment
"
```

### Step 4: Create GitHub Repository

1. Go to [https://github.com/new](https://github.com/new)
2. Repository name: `devops-task-manager`
3. Description: "Production-ready DevOps project with AWS EKS, Terraform, CI/CD, and monitoring"
4. Public or Private (your choice)
5. **Do NOT** check "Initialize with README"
6. Click "Create repository"

### Step 5: Add Remote and Push

Replace `YOUR_USERNAME` with your GitHub username:

```bash
git remote add origin https://github.com/YOUR_USERNAME/devops-task-manager.git
git branch -M main
git push -u origin main
```

## Post-Setup Configuration

### 1. Add Repository Description

On your GitHub repository page:
- Click "Edit" (⚙️ icon)
- Add description: "Production-ready DevOps project with AWS EKS, Terraform, Jenkins CI/CD, Prometheus/Grafana monitoring, and comprehensive documentation"
- Add topics: `devops`, `aws`, `eks`, `terraform`, `kubernetes`, `docker`, `cicd`, `jenkins`, `prometheus`, `grafana`, `nodejs`, `react`, `postgresql`

### 2. Configure GitHub Actions (Optional)

If you want to use GitHub Actions for CI/CD:

1. Go to repository Settings → Secrets and variables → Actions
2. Add secrets:
   - `AWS_ACCESS_KEY_ID`: Your AWS access key
   - `AWS_SECRET_ACCESS_KEY`: Your AWS secret key
3. GitHub Actions will automatically run on push to main/develop

### 3. Setup Jenkins Webhook (Optional)

If you're using Jenkins:

1. Deploy Jenkins first: `./jenkins/setup-jenkins.sh`
2. Get Jenkins URL: `kubectl get svc jenkins -n jenkins`
3. Go to GitHub repository Settings → Webhooks → Add webhook
4. Payload URL: `http://<JENKINS_URL>/github-webhook/`
5. Content type: `application/json`
6. Select "Just the push event"
7. Active: ✓

### 4. Create README Badges

Add these badges to the top of your README.md:

```markdown
# DevOps Task Manager

![AWS](https://img.shields.io/badge/AWS-EKS-orange?logo=amazon-aws)
![Terraform](https://img.shields.io/badge/IaC-Terraform-7B42BC?logo=terraform)
![Kubernetes](https://img.shields.io/badge/Orchestration-Kubernetes-326CE5?logo=kubernetes)
![Docker](https://img.shields.io/badge/Container-Docker-2496ED?logo=docker)
![Node.js](https://img.shields.io/badge/Backend-Node.js-339933?logo=node.js)
![React](https://img.shields.io/badge/Frontend-React-61DAFB?logo=react)
![PostgreSQL](https://img.shields.io/badge/Database-PostgreSQL-336791?logo=postgresql)
![Jenkins](https://img.shields.io/badge/CI/CD-Jenkins-D24939?logo=jenkins)
![Prometheus](https://img.shields.io/badge/Monitoring-Prometheus-E6522C?logo=prometheus)
![Grafana](https://img.shields.io/badge/Visualization-Grafana-F46800?logo=grafana)
```

### 5. Create Project Wiki (Optional)

GitHub Wiki is great for additional documentation:

1. Go to repository → Wiki → Create the first page
2. Add pages for:
   - Deployment Guide
   - Architecture Overview
   - Troubleshooting
   - FAQ

### 6. Setup GitHub Projects (Optional)

Track improvements and issues:

1. Go to repository → Projects → New project
2. Create boards for:
   - To Do
   - In Progress
   - Done

## Repository Structure

Your GitHub repository will have:

```
devops-task-manager/
├── 📱 backend/                  # Node.js backend
├── 🎨 frontend/                 # React frontend
├── 🏗️ terraform/                # Infrastructure as Code
├── ☸️ kubernetes/               # K8s manifests
├── 🔧 jenkins/                  # CI/CD configuration
├── 📜 scripts/                  # Automation scripts
├── 📊 monitoring/               # Monitoring configs
├── 📖 Documentation files       # Guides
├── .github/workflows/           # GitHub Actions
├── .gitignore
└── README.md
```

## Make Your Repository Stand Out

### 1. Add a Great README

Your README.md already includes:
- ✅ Architecture diagrams
- ✅ Quick start guide
- ✅ Comprehensive documentation
- ✅ Screenshots (add these!)

### 2. Add Screenshots

Create a `screenshots/` directory and add:
- Application UI
- Grafana dashboards
- Architecture diagrams
- CI/CD pipeline views

### 3. Create Releases

After pushing:

```bash
git tag -a v1.0.0 -m "Initial release"
git push origin v1.0.0
```

Then create a release on GitHub with release notes.

### 4. Add License

Create LICENSE file (MIT recommended):

```bash
cat > LICENSE << 'EOF'
MIT License

Copyright (c) 2024 [Your Name]

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
EOF

git add LICENSE
git commit -m "Add MIT license"
git push
```

## Security Considerations

### Files Already Ignored (via .gitignore)

The following are already excluded:
- ✅ `.env` files
- ✅ Terraform state files
- ✅ `node_modules/`
- ✅ Credentials and secrets
- ✅ AWS configuration
- ✅ Build artifacts

### Never Commit

- ❌ AWS credentials
- ❌ Database passwords
- ❌ Private keys
- ❌ `.env` files with secrets
- ❌ Terraform state with sensitive data

### Use GitHub Secrets

For sensitive values needed in CI/CD:
- Use GitHub Secrets (Settings → Secrets)
- Reference in workflows: `${{ secrets.SECRET_NAME }}`

## Troubleshooting

### Large File Warning

If you get warnings about large files:

```bash
# Check file sizes
find . -type f -size +50M

# If needed, use Git LFS for large files
git lfs install
git lfs track "*.zip"
git add .gitattributes
```

### Authentication Failed

If push fails with authentication error:

**Using HTTPS:**
1. Use Personal Access Token instead of password
2. Generate at: https://github.com/settings/tokens

**Using SSH:**
```bash
# Generate SSH key
ssh-keygen -t ed25519 -C "your_email@example.com"

# Add to SSH agent
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# Add to GitHub: Settings → SSH keys → New SSH key
cat ~/.ssh/id_ed25519.pub

# Change remote to SSH
git remote set-url origin git@github.com:YOUR_USERNAME/devops-task-manager.git
```

### Already Exists Error

If you initialized the GitHub repo with files:

```bash
# Pull first, then push
git pull origin main --allow-unrelated-histories
git push -u origin main
```

## Sharing Your Project

Once on GitHub, share it:

1. **LinkedIn**: "Just built a production-ready DevOps project with AWS EKS, Terraform, CI/CD, and monitoring! [link]"
2. **Twitter**: "Check out my full-stack DevOps project on GitHub! #DevOps #AWS #Kubernetes [link]"
3. **Portfolio**: Add to your personal website
4. **Job Applications**: Include GitHub link in resume

## Example Repository Description

```
Production-ready DevOps Task Manager application demonstrating:
- 🏗️ Infrastructure as Code with Terraform
- ☸️ Kubernetes orchestration on AWS EKS
- 🔄 CI/CD with Jenkins and GitHub Actions
- 📊 Monitoring with Prometheus and Grafana
- 🐳 Containerization with Docker
- 🔐 Security best practices
- 📈 Auto-scaling and high availability
- 📚 Comprehensive documentation

Tech Stack: React, Node.js, PostgreSQL, AWS EKS, Terraform, Kubernetes, Docker, Jenkins, Prometheus, Grafana
```

## Next Steps After Push

1. ✅ Verify all files are on GitHub
2. ✅ Check that .gitignore is working (no secrets uploaded)
3. ✅ Update README with your GitHub username
4. ✅ Add repository description and topics
5. ✅ Star your own repository 😊
6. ✅ Share with the community

---

**Ready to push?** Run `./setup-git.sh` to get started!

