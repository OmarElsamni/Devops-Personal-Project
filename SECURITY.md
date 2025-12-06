# Security Guidelines

## ⚠️ Important - Do Not Commit Secrets!

This repository contains **template files only**. Never commit actual secrets, passwords, or credentials.

## 🔒 Files to NEVER Commit

- ❌ `SAVE_THIS_PASSWORD.txt` - Database passwords
- ❌ `.env` files with real credentials
- ❌ `*.tfvars` with actual values
- ❌ AWS access keys
- ❌ Private keys (*.pem, *.key)
- ❌ Database connection strings with passwords

## ✅ How to Handle Secrets

### For Local Development

1. Copy template files:
```bash
cp backend/.env.example backend/.env
# Edit backend/.env with your local values
```

2. Never commit the actual `.env` file (it's in .gitignore)

### For Production

Use one of these secure methods:

#### Option 1: Kubernetes Secrets (Current Approach)
```bash
kubectl create secret generic database-secret \
    --from-literal=host=YOUR_RDS_ENDPOINT \
    --from-literal=database=taskdb \
    --from-literal=username=YOUR_USERNAME \
    --from-literal=password=YOUR_PASSWORD \
    -n task-manager
```

#### Option 2: AWS Secrets Manager (Recommended for Production)
```bash
# Store secret
aws secretsmanager create-secret \
    --name devops-project/database \
    --secret-string '{"username":"admin","password":"YOUR_PASSWORD"}'

# Reference in your application
```

#### Option 3: External Secrets Operator
```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: database-secret
spec:
  secretStoreRef:
    name: aws-secrets-manager
  target:
    name: database-secret
  data:
    - secretKey: password
      remoteRef:
        key: devops-project/database
```

### For CI/CD

#### GitHub Actions
Store secrets in: Repository Settings → Secrets and variables → Actions

Required secrets:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

#### Jenkins
Store in: Manage Jenkins → Credentials

## 🔍 Before Making Repository Public

Run this checklist:

- [ ] Remove `SAVE_THIS_PASSWORD.txt` from git history
- [ ] Check no `.env` files are committed
- [ ] Verify no AWS keys in code
- [ ] Replace example values in documentation
- [ ] Update `secret-template.yaml` to have placeholder values only

## 🧹 Clean Git History

If you accidentally committed secrets:

```bash
# Remove file from git history
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch SAVE_THIS_PASSWORD.txt" \
  --prune-empty --tag-name-filter cat -- --all

# Force push (only if repository is private/personal)
git push origin --force --all
```

**Note:** Only use force push if you're the only one using the repository!

## 📋 Safe to Commit

These files are safe and should be in git:
- ✅ Template files (*.example, *-template.yaml)
- ✅ Documentation
- ✅ Code without hardcoded secrets
- ✅ Terraform files (without *.tfvars)
- ✅ Kubernetes manifests (using variables)
- ✅ CI/CD configurations (referencing secrets, not containing them)

## 🎯 Best Practices

1. **Use environment variables** - Never hardcode
2. **Use secret management tools** - AWS Secrets Manager, HashiCorp Vault
3. **Rotate secrets regularly** - Change passwords periodically
4. **Least privilege access** - IAM roles with minimal permissions
5. **Audit access** - Monitor who accesses secrets
6. **Enable 2FA** - On all critical accounts

## 🚨 If Secrets Are Exposed

If you accidentally pushed secrets:

1. **Immediately rotate** the exposed credentials
2. **Clean git history** (see above)
3. **Force push** to remove from GitHub
4. **Check AWS CloudTrail** for unauthorized access
5. **Update all affected services** with new credentials

## 📚 Additional Resources

- [GitHub Secret Scanning](https://docs.github.com/en/code-security/secret-scanning)
- [AWS Secrets Manager](https://aws.amazon.com/secrets-manager/)
- [Kubernetes Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)
- [OWASP Secrets Management](https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html)

