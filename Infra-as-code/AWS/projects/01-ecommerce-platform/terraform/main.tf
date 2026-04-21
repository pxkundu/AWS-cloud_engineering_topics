terraform {
  required_version = ">= 1.6"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
  backend "s3" {
    bucket         = "ecommerce-tfstate-prod"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Project     = "ecommerce"
      Environment = var.environment
      ManagedBy   = "terraform"
      Owner       = "platform-team"
    }
  }
}

# ── VPC ──────────────────────────────────────────────────────────────────────
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.0"

  name = "${var.project}-${var.environment}-vpc"
  cidr = var.vpc_cidr
  azs  = var.availability_zones

  public_subnets   = var.public_subnet_cidrs
  private_subnets  = var.private_subnet_cidrs
  database_subnets = var.database_subnet_cidrs

  enable_nat_gateway     = true
  one_nat_gateway_per_az = var.environment == "prod"
  enable_dns_hostnames   = true
  enable_dns_support     = true

  create_database_subnet_group       = true
  create_database_subnet_route_table = true

  public_subnet_tags  = { "kubernetes.io/role/elb" = "1" }
  private_subnet_tags = { "kubernetes.io/role/internal-elb" = "1" }
}

# ── ECS Cluster ───────────────────────────────────────────────────────────────
module "ecs" {
  source = "./modules/ecs"

  cluster_name    = "${var.project}-${var.environment}"
  vpc_id          = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets
  public_subnets  = module.vpc.public_subnets
  alb_sg_id       = module.security_groups.alb_sg_id
  ecs_sg_id       = module.security_groups.ecs_sg_id
  ecr_repo_url    = var.ecr_repo_url
  image_tag       = var.image_tag
  certificate_arn = var.certificate_arn
}

# ── Aurora PostgreSQL ─────────────────────────────────────────────────────────
module "aurora" {
  source  = "terraform-aws-modules/rds-aurora/aws"
  version = "9.0.0"

  name            = "${var.project}-${var.environment}-db"
  engine          = "aurora-postgresql"
  engine_version  = "15.4"
  instance_class  = var.db_instance_class
  instances       = { for i in range(var.db_instance_count) : i => {} }

  vpc_id               = module.vpc.vpc_id
  db_subnet_group_name = module.vpc.database_subnet_group_name

  security_group_rules = {
    ecs_ingress = {
      source_security_group_id = module.security_groups.ecs_sg_id
    }
  }

  storage_encrypted   = true
  deletion_protection = var.environment == "prod"
  skip_final_snapshot = var.environment != "prod"

  manage_master_user_password = true  # Secrets Manager rotation

  monitoring_interval             = 60
  performance_insights_enabled    = true
  performance_insights_retention_period = 7
}

# ── ElastiCache Redis ─────────────────────────────────────────────────────────
module "elasticache" {
  source = "./modules/elasticache"

  cluster_id      = "${var.project}-${var.environment}-cache"
  node_type       = var.cache_node_type
  num_cache_nodes = var.environment == "prod" ? 3 : 1
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.database_subnets
  allowed_sg_id   = module.security_groups.ecs_sg_id
}

# ── CloudFront + S3 ───────────────────────────────────────────────────────────
module "cdn" {
  source = "./modules/cdn"

  project     = var.project
  environment = var.environment
  alb_dns     = module.ecs.alb_dns_name
}

# ── Security Groups ───────────────────────────────────────────────────────────
module "security_groups" {
  source = "./modules/security-groups"

  project    = var.project
  environment = var.environment
  vpc_id     = module.vpc.vpc_id
  vpc_cidr   = var.vpc_cidr
}
