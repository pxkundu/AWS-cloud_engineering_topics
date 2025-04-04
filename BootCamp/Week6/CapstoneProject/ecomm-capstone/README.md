# E-commerce Capstone Project on AWS EKS

## Overview
A secure, scalable microservices-based e-commerce platform on AWS EKS, designed for 10,000+ products and 100K+ transactions/day. Built with Kubernetes best practices and DevSecOps principles.

## Prerequisites
- AWS account (EKS, ECR, S3, RDS access).
- Terraform, Helm, kubectl, AWS CLI installed.
- GitHub account with secrets (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY).
- ACM certificate for TLS.

## Setup
### Phase 1: Planning
1. Clone repo: `git clone <repo-url>`
2. Navigate to project: `cd ecomm-capstone`
3. Review `docs/ecomm-architecture.md`.

### Phase 2: Build and Automate
1. Configure Terraform variables in `infrastructure/terraform/variables.tf` (VPC, subnets).
2. Deploy EKS: `cd infrastructure/terraform && terraform init && terraform apply`.
3. Build and push Docker images:
   - Frontend: `docker build -t <ecr-repo>/frontend:latest ./frontend && docker push ...`
   - Backend: `docker build -t <ecr-repo>/backend:latest ./backend && docker push ...`
4. Deploy to EKS: `kubectl apply -f frontend/kubernetes/ -f backend/kubernetes/ -f kubernetes/ingress.yaml`.
5. Test CI/CD: Push changes to GitHub, verify pipelines.
6. Simulate DDoS: `ab -n 10000 -c 100 <alb-url>`.

## Structure
- `docs/`: Architecture and runbooks.
- `frontend/`, `backend/`: Microservices.
- `infrastructure/`: Terraform and Helm configs.
- `kubernetes/`: Cluster-wide manifests.
- `.github/`: CI/CD workflows.
