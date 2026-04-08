# 🚀 EKS FastAPI Demo — Production Kubernetes on AWS

> **Portfolio project by [Carlos Figueiredo](https://github.com/devcarlosfigueiredo)**  
> Demonstrates end-to-end production Kubernetes: Terraform → EKS → Helm → GitOps CI/CD

[![CI — Build & Test](https://github.com/devcarlosfigueiredo/eks-fastapi-demo/actions/workflows/ci.yml/badge.svg)](https://github.com/devcarlosfigueiredo/eks-fastapi-demo/actions/workflows/ci.yml)
[![CD — Deploy to EKS](https://github.com/devcarlosfigueiredo/eks-fastapi-demo/actions/workflows/deploy.yml/badge.svg)](https://github.com/devcarlosfigueiredo/eks-fastapi-demo/actions/workflows/deploy.yml)

---

## 📐 Architecture

```
Developer pushes to main
        │
        ▼
┌─────────────────────────────────────────┐
│           GitHub Actions CI             │
│  pytest → ruff → docker build →         │
│  trivy scan → push to ECR               │
└──────────────────┬──────────────────────┘
                   │ image: ECR_URI:SHA
                   ▼
┌─────────────────────────────────────────┐
│           GitHub Actions CD             │
│  helm upgrade --install --atomic        │
│  smoke test /health → rollback on fail  │
└──────────────────┬──────────────────────┘
                   │
                   ▼
     ┌─────────────────────────┐
     │      AWS EKS Cluster    │
     │  ┌───────────────────┐  │
     │  │   AWS ALB Ingress │  │◄── Internet traffic
     │  └────────┬──────────┘  │
     │           │             │
     │  ┌────────▼──────────┐  │
     │  │  K8s Service      │  │
     │  └────────┬──────────┘  │
     │           │             │
     │  ┌────────▼──────────┐  │
     │  │  Pods (2-10)      │  │
     │  │  FastAPI + Uvicorn│  │
     │  └───────────────────┘  │
     │           ▲             │
     │  ┌────────┴──────────┐  │
     │  │  HPA + Metrics    │  │
     │  │  Server           │  │
     │  └───────────────────┘  │
     └─────────────────────────┘
```

## 🧠 Technologies

| Layer | Technology |
|---|---|
| Application | Python 3.12 + FastAPI + Uvicorn |
| Container | Docker (multi-stage, non-root) |
| Registry | Amazon ECR |
| Orchestration | Amazon EKS (Kubernetes 1.30) |
| Infra as Code | Terraform + AWS VPC/EKS modules |
| Package Manager | Helm 3 |
| CI/CD | GitHub Actions (OIDC — no static keys) |
| Autoscaling | Kubernetes HPA (CPU + Memory) |
| Ingress | AWS Load Balancer Controller (ALB) |
| Security | IRSA, Trivy, non-root containers, read-only FS |

---

## 📂 Project Structure

```
.
├── app/
│   └── main.py                     # FastAPI: /, /health, /ready, /info, /metrics
├── tests/
│   └── test_main.py                # pytest — 80%+ coverage enforced
├── Dockerfile                      # Multi-stage, non-root, Docker HEALTHCHECK
├── requirements.txt
│
├── terraform/
│   ├── vpc/
│   │   ├── main.tf                 # VPC + public/private subnets + NAT GW
│   │   └── variables.tf
│   └── eks-cluster/
│       ├── provider.tf             # AWS + Kubernetes + Helm providers
│       ├── main.tf                 # EKS cluster, node group, IRSA, ALB controller
│       ├── variables.tf
│       └── outputs.tf
│
├── helm/
│   └── myapp/
│       ├── Chart.yaml
│       ├── values.yaml             # Dev defaults
│       ├── values-prod.yaml        # Production overrides
│       └── templates/
│           ├── _helpers.tpl
│           ├── deployment.yaml     # RollingUpdate, probes, security context
│           ├── service.yaml
│           ├── ingress.yaml        # AWS ALB annotations
│           ├── hpa.yaml            # min:2 max:10 CPU:70% — autoscaling/v2
│           ├── configmap.yaml
│           ├── serviceaccount.yaml # IRSA annotation
│           └── pdb.yaml            # PodDisruptionBudget
│
└── .github/workflows/
    ├── ci.yml                      # Build → Test → Trivy Scan → Push ECR
    └── deploy.yml                  # Helm deploy → smoke test → rollback
```

---

## ⚡ Quick Start

### Prerequisites

```bash
# Required tools
aws --version          # AWS CLI v2
terraform --version    # >= 1.7
helm version           # >= 3.14
kubectl version        # >= 1.28
```

### 1 — Clone the repository

```bash
git clone https://github.com/devcarlosfigueiredo/eks-fastapi-demo.git
cd eks-fastapi-demo
```

### 2 — Run the app locally

```bash
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000

# Test endpoints
curl http://localhost:8000/
curl http://localhost:8000/health
curl http://localhost:8000/ready
curl http://localhost:8000/metrics
```

### 3 — Run tests

```bash
pytest tests/ -v --cov=app --cov-report=term-missing
```

### 4 — Provision infrastructure with Terraform

```bash
# Step 1: VPC
cd terraform/vpc
terraform init
terraform plan
terraform apply

# Step 2: EKS Cluster (pass VPC outputs as variables)
cd ../eks-cluster
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
terraform init
terraform plan
terraform apply

# Configure kubectl
$(terraform output -raw kubeconfig_command)
kubectl get nodes
```

### 5 — Deploy with Helm (manual)

```bash
# Authenticate Docker to ECR
aws ecr get-login-password --region eu-west-1 | \
  docker login --username AWS --password-stdin \
  <AWS_ACCOUNT_ID>.dkr.ecr.eu-west-1.amazonaws.com

# Build and push
docker build -t eks-fastapi-demo:latest .
docker tag eks-fastapi-demo:latest \
  <AWS_ACCOUNT_ID>.dkr.ecr.eu-west-1.amazonaws.com/eks-fastapi-demo:latest
docker push <AWS_ACCOUNT_ID>.dkr.ecr.eu-west-1.amazonaws.com/eks-fastapi-demo:latest

# Deploy to dev
helm upgrade --install myapp ./helm/myapp/ \
  --namespace myapp-dev --create-namespace \
  --set image.repository=<AWS_ACCOUNT_ID>.dkr.ecr.eu-west-1.amazonaws.com/eks-fastapi-demo \
  --set image.tag=latest

# Deploy to production
helm upgrade --install myapp ./helm/myapp/ \
  --namespace myapp-production --create-namespace \
  -f helm/myapp/values.yaml \
  -f helm/myapp/values-prod.yaml \
  --set image.repository=<ECR_URI> \
  --set image.tag=<SHA> \
  --atomic --timeout 5m
```

---

## 🔐 GitHub Actions Setup

### Required Secrets

| Secret | Description |
|---|---|
| `AWS_GITHUB_ACTIONS_ROLE_ARN` | IAM Role ARN for OIDC (no static keys!) |
| `APP_IRSA_ROLE_ARN` | IAM Role ARN for app service account |

### Setting up OIDC (no static AWS keys)

```bash
# Create OIDC provider for GitHub Actions in your AWS account
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1

# Create IAM role that trusts GitHub Actions OIDC
# Trust policy: only your repo can assume this role
```

Trust policy for the IAM role:

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {
      "Federated": "arn:aws:iam::<ACCOUNT_ID>:oidc-provider/token.actions.githubusercontent.com"
    },
    "Action": "sts:AssumeRoleWithWebIdentity",
    "Condition": {
      "StringEquals": {
        "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
      },
      "StringLike": {
        "token.actions.githubusercontent.com:sub": "repo:devcarlosfigueiredo/eks-fastapi-demo:*"
      }
    }
  }]
}
```

---

## 📊 Autoscaling

The HPA scales between **2 and 10 pods** based on CPU (70%) and Memory (80%):

```bash
# Watch HPA in real-time
kubectl get hpa -n myapp-production -w

# Generate load to trigger scale-up
kubectl run load-generator --image=busybox --restart=Never -it -- \
  /bin/sh -c "while true; do wget -q -O- http://myapp-myapp/; done"

# Check metrics
kubectl top pods -n myapp-production
```

---

## 🔎 Observability

```bash
# Application logs
kubectl logs -n myapp-production -l app.kubernetes.io/name=myapp -f

# Describe deployment
kubectl describe deployment myapp-myapp -n myapp-production

# Events
kubectl get events -n myapp-production --sort-by='.lastTimestamp'

# Helm history (all releases)
helm history myapp -n myapp-production

# Manual rollback
helm rollback myapp 1 -n myapp-production
```

---

## 🛡️ Security Practices

- **IRSA**: pods access AWS via IAM role — never static credentials
- **Non-root**: container runs as UID 1001
- **Read-only filesystem**: `readOnlyRootFilesystem: true` (tmpdir via emptyDir)
- **No privilege escalation**: `allowPrivilegeEscalation: false`
- **Resource limits**: CPU and memory defined on every pod
- **Trivy scan**: CI fails on CRITICAL/HIGH CVEs
- **PodDisruptionBudget**: enabled in production (minAvailable: 2)

---

## 👤 Author

**Carlos Figueiredo**  
DevOps / Platform Engineer  
🔗 [github.com/devcarlosfigueiredo](https://github.com/devcarlosfigueiredo)
