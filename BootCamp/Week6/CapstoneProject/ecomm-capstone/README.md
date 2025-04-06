# E-commerce Capstone Project on AWS EKS

## Overview
A secure, scalable microservices-based e-commerce platform on AWS EKS, designed for 10,000+ products and 100K+ transactions/day. Built with Kubernetes best practices and DevSecOps principles.

## Prerequisites
- AWS account (EKS, ECR, S3, RDS, ACM).
- Terraform, kubectl, AWS CLI, Node.js, Docker, Git.
- GitHub repo with secrets (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY).
- ACM certificate for TLS.

## Setup
### Phase 1: Planning
1. Clone repo: `git clone <repo-url>`
2. Review `docs/ecomm-architecture.md`.

### Phase 2: Build and Automate
1. Deploy EKS: `cd infrastructure/terraform && terraform init && terraform apply`.
2. Build/push images: `docker build -t <ecr-repo>/frontend:latest ./frontend` (and backend).
3. Deploy: `kubectl apply -f frontend/kubernetes/ -f backend/kubernetes/ -f kubernetes/ingress.yaml`.
4. Test CI/CD: Push to GitHub, verify pipelines.

### Phase 3: Secure and Monitor
1. Apply security: `kubectl apply -f kubernetes/rbac/ -f kubernetes/netpol.yaml -f kubernetes/opa/`.
2. Enable observability: Update backend with X-Ray, set CloudWatch alarm.
3. Pass pen test: Run `kube-hunter`, fix issues.

### Phase 4: Chaos Crunch
1. Apply HPA: `kubectl apply -f kubernetes/hpa-frontend.yaml -f kubernetes/hpa-backend.yaml`.
2. Simulate chaos:
   - Pod failure: `kubectl delete pod -l app=frontend --force -n prod` (50% pods).
   - Traffic spike: `ab -n 10000 -c 100 <alb-url>`.
3. Monitor recovery:
   - Pods: `kubectl get pods -n prod -w`
   - Nodes: `kubectl get nodes`
   - CloudWatch/X-Ray for metrics/traces.
4. Review runbook: `cat docs/runbook.md`.

## Structure
- `docs/`: Architecture and runbook.
- `frontend/`, `backend/`: Microservices.
- `infrastructure/`: Terraform and Helm configs.
- `kubernetes/`: Cluster-wide manifests (HPA, RBAC, etc.).
- `.github/`: CI/CD workflows.

## Verification
- Pods recover from 50% kill in <5 min.
- System scales to 10 pods, 4 nodes during spike, then stabilizes.
- Runbook resolves chaos scenarios effectively.
