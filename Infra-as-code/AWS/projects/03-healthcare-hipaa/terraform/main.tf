terraform {
  required_version = ">= 1.6"
  required_providers {
    aws        = { source = "hashicorp/aws",        version = "~> 5.0"  }
    helm       = { source = "hashicorp/helm",       version = "~> 2.12" }
    kubernetes = { source = "hashicorp/kubernetes", version = "~> 2.24" }
    kubectl    = { source = "gavinbunney/kubectl",  version = "~> 1.14" }
  }
  backend "s3" {
    bucket         = "healthcare-tfstate-prod"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
    kms_key_id     = "alias/healthcare-terraform-state"
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Project    = "healthcare-platform"
      Environment = var.environment
      ManagedBy  = "terraform"
      Compliance = "HIPAA"
    }
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    }
  }
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

# ── KMS ───────────────────────────────────────────────────────────────────────
resource "aws_kms_key" "eks" {
  description             = "EKS secrets encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true
}

# ── VPC ───────────────────────────────────────────────────────────────────────
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.0"

  name = "healthcare-${var.environment}-vpc"
  cidr = "10.2.0.0/16"
  azs  = ["us-east-1a", "us-east-1b", "us-east-1c"]

  private_subnets  = ["10.2.1.0/24", "10.2.2.0/24", "10.2.3.0/24"]
  public_subnets   = ["10.2.11.0/24", "10.2.12.0/24", "10.2.13.0/24"]
  database_subnets = ["10.2.21.0/24", "10.2.22.0/24", "10.2.23.0/24"]

  enable_nat_gateway     = true
  one_nat_gateway_per_az = true
  enable_dns_hostnames   = true

  # Required for EKS
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"                         = "1"
    "kubernetes.io/cluster/healthcare-${var.environment}"     = "owned"
  }
  public_subnet_tags = {
    "kubernetes.io/role/elb"                                  = "1"
    "kubernetes.io/cluster/healthcare-${var.environment}"     = "owned"
  }

  # HIPAA: VPC Flow Logs
  enable_flow_log                      = true
  create_flow_log_cloudwatch_log_group = true
  create_flow_log_cloudwatch_iam_role  = true
}

# ── EKS Cluster ───────────────────────────────────────────────────────────────
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.0.0"

  cluster_name    = "healthcare-${var.environment}"
  cluster_version = "1.29"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # HIPAA: Private cluster
  cluster_endpoint_public_access  = false
  cluster_endpoint_private_access = true

  # HIPAA: Encrypt secrets at rest
  cluster_encryption_config = {
    resources        = ["secrets"]
    provider_key_arn = aws_kms_key.eks.arn
  }

  # HIPAA: Full audit logging
  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  # IRSA
  enable_irsa = true

  # EKS Managed Addons
  cluster_addons = {
    coredns            = { most_recent = true }
    kube-proxy         = { most_recent = true }
    vpc-cni            = { most_recent = true }
    aws-ebs-csi-driver = { most_recent = true }
  }

  eks_managed_node_groups = {
    system = {
      instance_types = ["t3.large"]
      min_size       = 3
      max_size       = 5
      desired_size   = 3
      labels         = { role = "system" }
      taints         = [{ key = "CriticalAddonsOnly", value = "true", effect = "NO_SCHEDULE" }]
      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 50
            volume_type           = "gp3"
            encrypted             = true
            kms_key_id            = aws_kms_key.eks.arn
            delete_on_termination = true
          }
        }
      }
    }
    app = {
      instance_types = ["m5.xlarge"]
      min_size       = 3
      max_size       = 20
      desired_size   = 3
      labels         = { role = "app" }
      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 100
            volume_type           = "gp3"
            encrypted             = true
            kms_key_id            = aws_kms_key.eks.arn
            delete_on_termination = true
          }
        }
      }
    }
  }
}

# ── Karpenter ─────────────────────────────────────────────────────────────────
module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "20.0.0"

  cluster_name                    = module.eks.cluster_name
  irsa_oidc_provider_arn          = module.eks.oidc_provider_arn
  irsa_namespace_service_accounts = ["karpenter:karpenter"]
}

resource "helm_release" "karpenter" {
  namespace        = "karpenter"
  create_namespace = true
  name             = "karpenter"
  repository       = "oci://public.ecr.aws/karpenter"
  chart            = "karpenter"
  version          = "v0.33.0"

  set { name = "settings.clusterName",       value = module.eks.cluster_name }
  set { name = "settings.interruptionQueue", value = module.karpenter.queue_name }
  set { name = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn", value = module.karpenter.irsa_arn }
}

# ── ArgoCD ────────────────────────────────────────────────────────────────────
resource "helm_release" "argocd" {
  name             = "argocd"
  namespace        = "argocd"
  create_namespace = true
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "6.0.0"

  values = [file("${path.module}/helm-values/argocd.yaml")]
}

# ── Observability Stack ───────────────────────────────────────────────────────
resource "helm_release" "kube_prometheus" {
  name             = "kube-prometheus-stack"
  namespace        = "monitoring"
  create_namespace = true
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  version          = "55.0.0"

  values = [file("${path.module}/helm-values/prometheus.yaml")]
}

resource "helm_release" "loki" {
  name             = "loki"
  namespace        = "monitoring"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "loki-stack"
  version          = "2.10.0"
}

# ── External Secrets Operator ─────────────────────────────────────────────────
resource "helm_release" "external_secrets" {
  name             = "external-secrets"
  namespace        = "external-secrets"
  create_namespace = true
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  version          = "0.9.0"
}

# ── Aurora PostgreSQL (HIPAA) ─────────────────────────────────────────────────
module "aurora" {
  source  = "terraform-aws-modules/rds-aurora/aws"
  version = "9.0.0"

  name           = "healthcare-${var.environment}-db"
  engine         = "aurora-postgresql"
  engine_version = "15.4"
  instance_class = "db.r6g.xlarge"
  instances      = { 1 = {}, 2 = {}, 3 = {} }

  vpc_id               = module.vpc.vpc_id
  db_subnet_group_name = module.vpc.database_subnet_group_name

  storage_encrypted   = true
  kms_key_id          = aws_kms_key.eks.arn
  deletion_protection = true
  skip_final_snapshot = false

  # HIPAA: Enhanced monitoring
  monitoring_interval                   = 30
  performance_insights_enabled          = true
  performance_insights_kms_key_id       = aws_kms_key.eks.arn
  performance_insights_retention_period = 731  # 2 years

  # HIPAA: Audit logging
  enabled_cloudwatch_logs_exports = ["postgresql"]

  manage_master_user_password = true
}
