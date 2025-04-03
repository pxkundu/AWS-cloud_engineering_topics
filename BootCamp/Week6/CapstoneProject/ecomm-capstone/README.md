# E-commerce Capstone Project on AWS EKS

## Overview
A secure, scalable microservices-based e-commerce platform on AWS EKS, designed for 10,000+ products and 100K+ transactions/day. Built with Kubernetes best practices and DevSecOps principles.

## Prerequisites
- AWS account (EKS, ECR, S3, RDS access).
- Terraform, Helm, kubectl installed.
- GitHub account for CI/CD.

## Setup
1. Clone repo: `git clone <repo-url>`
2. Navigate to project: `cd ecomm-capstone`
3. Follow phase-specific instructions in `docs/`.

## Structure
- `docs/`: Architecture and runbooks.
- `frontend/`, `backend/`: Microservices.
- `infrastructure/`: Terraform and Helm configs.
- `kubernetes/`: Cluster-wide manifests.
- `.github/`: CI/CD workflows.
