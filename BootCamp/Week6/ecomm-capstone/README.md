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
1. Apply security configs:
   - RBAC: `kubectl apply -f kubernetes/rbac/`
   - Network Policy: `kubectl apply -f kubernetes/netpol.yaml`
   - OPA Gatekeeper: `kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/master/deploy/gatekeeper.yaml && kubectl apply -f kubernetes/opa/`
2. Update backend for observability:
   - Rebuild/push: `cd backend && docker build -t <ecr-repo>/backend:latest . && docker push ...`
   - Redeploy: `kubectl apply -f backend/kubernetes/`
3. Enable CloudWatch:
   - `aws eks update-cluster-config --name ecomm-cluster --region us-east-1 --logging '{"clusterLogging":[{"types":["api","audit","authenticator","controllerManager","scheduler"],"enabled":true}]}'`
   - Set alarm: `aws cloudwatch put-metric-alarm --alarm-name cpu-high --metric-name CPUUtilization --namespace AWS/EKS --threshold 80 --comparison-operator GreaterThanThreshold --evaluation-periods 2 --period 300 --statistic Average --alarm-actions <SNS_TOPIC_ARN>`
4. Run penetration test:
   - `docker run -it --rm --network host aquasec/kube-hunter`
   - Fix identified issues (e.g., tighten RBAC).

## Structure
- `docs/`: Architecture and runbooks.
- `frontend/`, `backend/`: Microservices.
- `infrastructure/`: Terraform and Helm configs.
- `kubernetes/`: Cluster-wide manifests (RBAC, Network Policies, OPA).
- `.github/`: CI/CD workflows.

## Verification
- RBAC: `kubectl auth can-i get pods -n prod --as=system:serviceaccount:prod:ecomm-sa`
- Network Policy: Traffic restricted to frontend → backend only.
- OPA: Privileged pod creation fails.
- CloudWatch: Metrics visible, alarm triggers on CPU > 80%.
- X-Ray: Traces show API calls.
- kube-hunter: No critical vulnerabilities.
