#!/bin/bash
# Setup Git Repository for GitHub

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Git Repository Setup for GitHub${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if git is installed
if ! command -v git &> /dev/null; then
    echo -e "${YELLOW}Git is not installed. Please install git first.${NC}"
    exit 1
fi

# Initialize git repository
echo -e "${GREEN}[1/5] Initializing git repository...${NC}"
git init

# Add all files
echo -e "${GREEN}[2/5] Adding all files to git...${NC}"
git add .

# Create initial commit
echo -e "${GREEN}[3/5] Creating initial commit...${NC}"
git commit -m "Initial commit: Complete DevOps Task Manager project

- Full-stack application (React + Node.js + PostgreSQL)
- Terraform infrastructure for AWS EKS
- Kubernetes manifests and Helm charts
- CI/CD pipelines (Jenkins + GitHub Actions)
- Prometheus and Grafana monitoring
- Comprehensive documentation
- Automation scripts for deployment

Features:
- Production-ready architecture
- Multi-AZ high availability
- Auto-scaling (HPA + CA)
- Security best practices
- Complete monitoring stack
- Automated CI/CD workflows
"

# Get GitHub username
echo ""
echo -e "${YELLOW}Enter your GitHub username:${NC}"
read GITHUB_USERNAME

# Get repository name
echo -e "${YELLOW}Enter repository name (default: devops-task-manager):${NC}"
read REPO_NAME
REPO_NAME=${REPO_NAME:-devops-task-manager}

# Set main branch
echo -e "${GREEN}[4/5] Setting main branch...${NC}"
git branch -M main

# Add remote origin
echo -e "${GREEN}[5/5] Adding GitHub remote...${NC}"
git remote add origin "https://github.com/${GITHUB_USERNAME}/${REPO_NAME}.git"

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}✅ Git repository initialized!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo ""
echo -e "1. Create a new repository on GitHub:"
echo -e "   ${BLUE}https://github.com/new${NC}"
echo -e "   Repository name: ${YELLOW}${REPO_NAME}${NC}"
echo -e "   ⚠️  Do NOT initialize with README, .gitignore, or license"
echo ""
echo -e "2. Push your code to GitHub:"
echo -e "   ${BLUE}git push -u origin main${NC}"
echo ""
echo -e "3. If using GitHub Actions, add these secrets in repository settings:"
echo -e "   - ${YELLOW}AWS_ACCESS_KEY_ID${NC}"
echo -e "   - ${YELLOW}AWS_SECRET_ACCESS_KEY${NC}"
echo ""
echo -e "4. For Jenkins webhook, add webhook in repository settings:"
echo -e "   Payload URL: ${YELLOW}http://<JENKINS_URL>/github-webhook/${NC}"
echo -e "   Content type: ${YELLOW}application/json${NC}"
echo ""
echo -e "Repository URL: ${GREEN}https://github.com/${GITHUB_USERNAME}/${REPO_NAME}${NC}"
echo ""

