#!/bin/bash
# ──────────────────────────────────────────────────────────────────────────────
# setup-github.sh — Inicializa o repositório e faz push para o GitHub
# Uso: bash setup-github.sh
# ──────────────────────────────────────────────────────────────────────────────
set -euo pipefail

GITHUB_USER="devcarlosfigueiredo"
REPO_NAME="eks-fastapi-demo"
REMOTE_URL="https://github.com/${GITHUB_USER}/${REPO_NAME}.git"

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║   EKS FastAPI Demo — GitHub Push Setup                  ║"
echo "║   github.com/${GITHUB_USER}                     ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# ── 1. Verificar se git está instalado ────────────────────────────────────────
if ! command -v git &>/dev/null; then
  echo "❌ git não encontrado. Instala com: brew install git  ou  apt install git"
  exit 1
fi

# ── 2. Verificar se estamos na pasta certa ────────────────────────────────────
if [ ! -f "README.md" ]; then
  echo "❌ Executa este script dentro da pasta do projecto (onde está o README.md)"
  exit 1
fi

# ── 3. Configurar identidade git (só se ainda não configurado) ────────────────
if [ -z "$(git config --global user.email 2>/dev/null || true)" ]; then
  read -rp "📧 Email do GitHub: " GIT_EMAIL
  git config --global user.email "$GIT_EMAIL"
fi

if [ -z "$(git config --global user.name 2>/dev/null || true)" ]; then
  read -rp "👤 Nome para commits: " GIT_NAME
  git config --global user.name "$GIT_NAME"
fi

# ── 4. Init + primeiro commit ─────────────────────────────────────────────────
echo ""
echo "🔧 Inicializando repositório git..."

git init
git add .
git commit -m "feat: initial commit — EKS FastAPI production project

Complete production-grade Kubernetes deployment on AWS EKS:
- FastAPI app with /health, /ready, /metrics endpoints
- Multi-stage Docker build (non-root, read-only filesystem)
- Terraform: VPC + EKS cluster + IRSA + ALB Controller
- Helm chart with dev/prod values, HPA (2-10 pods, CPU 70%)
- GitHub Actions: CI (build/test/scan) + CD (helm deploy + rollback)
- Security: IRSA, Trivy scan, PodDisruptionBudget

Author: Carlos Figueiredo — github.com/devcarlosfigueiredo"

# ── 5. Renomear branch para main ──────────────────────────────────────────────
git branch -M main

# ── 6. Verificar se remote já existe ─────────────────────────────────────────
if git remote get-url origin &>/dev/null; then
  echo "⚠️  Remote 'origin' já existe. A atualizar URL..."
  git remote set-url origin "$REMOTE_URL"
else
  git remote add origin "$REMOTE_URL"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⚠️  ANTES DE CONTINUAR:"
echo ""
echo "   Cria o repositório no GitHub (se ainda não existe):"
echo "   👉 https://github.com/new"
echo ""
echo "   Nome do repo : ${REPO_NAME}"
echo "   Visibilidade : Public  (recomendado para portfolio)"
echo "   NÃO inicializes com README, .gitignore ou license"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
read -rp "✅ Repositório criado? Prima ENTER para continuar ou Ctrl+C para cancelar..."

# ── 7. Push ───────────────────────────────────────────────────────────────────
echo ""
echo "🚀 A fazer push para ${REMOTE_URL}..."
echo "   (o GitHub vai pedir as tuas credenciais)"
echo ""

git push -u origin main

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║   ✅  Push concluído com sucesso!                        ║"
echo "╠══════════════════════════════════════════════════════════╣"
echo "║                                                          ║"
echo "║   🔗  https://github.com/${GITHUB_USER}/${REPO_NAME}  ║"
echo "║                                                          ║"
echo "║   📋  Próximos passos:                                   ║"
echo "║   1. Adiciona os Secrets no GitHub:                      ║"
echo "║      Settings → Secrets → Actions                        ║"
echo "║      - AWS_GITHUB_ACTIONS_ROLE_ARN                       ║"
echo "║      - APP_IRSA_ROLE_ARN                                 ║"
echo "║                                                          ║"
echo "║   2. terraform apply (vpc → eks-cluster)                 ║"
echo "║                                                          ║"
echo "║   3. Cria um ECR repo:                                   ║"
echo "║      aws ecr create-repository --name eks-fastapi-demo   ║"
echo "║                                                          ║"
echo "║   4. Faz push de uma branch → abre PR → merge!           ║"
echo "║      CI/CD dispara automaticamente.                      ║"
echo "║                                                          ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""
