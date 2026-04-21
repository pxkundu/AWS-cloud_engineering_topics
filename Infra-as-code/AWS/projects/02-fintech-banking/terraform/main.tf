terraform {
  required_version = ">= 1.6"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
  backend "s3" {
    bucket         = "fintech-tfstate-prod"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
    kms_key_id     = "alias/terraform-state"
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Project     = "fintech-banking"
      Environment = var.environment
      ManagedBy   = "terraform"
      Compliance  = "PCI-DSS"
    }
  }
}

# ── KMS Keys ──────────────────────────────────────────────────────────────────
resource "aws_kms_key" "main" {
  description             = "Fintech platform encryption key"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  multi_region            = true
}

resource "aws_kms_alias" "main" {
  name          = "alias/fintech-${var.environment}"
  target_key_id = aws_kms_key.main.key_id
}

# ── VPC ───────────────────────────────────────────────────────────────────────
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.0"

  name = "fintech-${var.environment}-vpc"
  cidr = "10.1.0.0/16"
  azs  = ["us-east-1a", "us-east-1b", "us-east-1c"]

  private_subnets  = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
  public_subnets   = ["10.1.11.0/24", "10.1.12.0/24", "10.1.13.0/24"]
  database_subnets = ["10.1.21.0/24", "10.1.22.0/24", "10.1.23.0/24"]

  enable_nat_gateway     = true
  one_nat_gateway_per_az = true
  enable_dns_hostnames   = true

  # VPC Flow Logs — required for PCI-DSS
  enable_flow_log                      = true
  create_flow_log_cloudwatch_log_group = true
  create_flow_log_cloudwatch_iam_role  = true
  flow_log_max_aggregation_interval    = 60
}

# ── Kinesis Data Stream ───────────────────────────────────────────────────────
resource "aws_kinesis_stream" "transactions" {
  name             = "fintech-${var.environment}-transactions"
  shard_count      = var.kinesis_shard_count
  retention_period = 168  # 7 days

  encryption_type = "KMS"
  kms_key_id      = aws_kms_key.main.id

  stream_mode_details {
    stream_mode = "PROVISIONED"
  }
}

# ── Step Functions ────────────────────────────────────────────────────────────
resource "aws_sfn_state_machine" "transaction_workflow" {
  name     = "fintech-${var.environment}-transaction-workflow"
  role_arn = aws_iam_role.sfn.arn
  type     = "EXPRESS"  # High throughput, low latency

  definition = templatefile("${path.module}/statemachine/transaction-workflow.json", {
    fraud_detector_arn = module.lambdas.fraud_detector_arn
    enricher_arn       = module.lambdas.enricher_arn
    table_name         = aws_dynamodb_table.transactions.name
    alert_topic_arn    = aws_sns_topic.fraud_alerts.arn
  })

  logging_configuration {
    log_destination        = "${aws_cloudwatch_log_group.sfn.arn}:*"
    include_execution_data = true
    level                  = "ALL"
  }

  tracing_configuration { enabled = true }
}

# ── DynamoDB — Single Table Design ───────────────────────────────────────────
resource "aws_dynamodb_table" "transactions" {
  name         = "fintech-${var.environment}-transactions"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "PK"
  range_key    = "SK"

  attribute { name = "PK",     type = "S" }
  attribute { name = "SK",     type = "S" }
  attribute { name = "GSI1PK", type = "S" }
  attribute { name = "GSI1SK", type = "S" }
  attribute { name = "GSI2PK", type = "S" }

  global_secondary_index {
    name            = "GSI1"
    hash_key        = "GSI1PK"
    range_key       = "GSI1SK"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "GSI2"
    hash_key        = "GSI2PK"
    range_key       = "SK"
    projection_type = "INCLUDE"
    non_key_attributes = ["amount", "status", "timestamp"]
  }

  point_in_time_recovery { enabled = true }

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.main.arn
  }

  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  deletion_protection_enabled = var.environment == "prod"
}

# ── Lambda Functions ──────────────────────────────────────────────────────────
module "lambdas" {
  source = "./modules/lambdas"

  project         = "fintech"
  environment     = var.environment
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnets
  kms_key_arn     = aws_kms_key.main.arn
  table_name      = aws_dynamodb_table.transactions.name
  stream_arn      = aws_kinesis_stream.transactions.arn
  sfn_arn         = aws_sfn_state_machine.transaction_workflow.arn
}

# ── SNS Alerts ────────────────────────────────────────────────────────────────
resource "aws_sns_topic" "fraud_alerts" {
  name              = "fintech-${var.environment}-fraud-alerts"
  kms_master_key_id = aws_kms_key.main.id
}

# ── CloudWatch Log Groups ─────────────────────────────────────────────────────
resource "aws_cloudwatch_log_group" "sfn" {
  name              = "/aws/states/fintech-${var.environment}-transaction-workflow"
  retention_in_days = 90
  kms_key_id        = aws_kms_key.main.arn
}

# ── IAM — Step Functions ──────────────────────────────────────────────────────
resource "aws_iam_role" "sfn" {
  name = "fintech-${var.environment}-sfn-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "states.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "sfn" {
  role = aws_iam_role.sfn.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["lambda:InvokeFunction"]
        Resource = [module.lambdas.fraud_detector_arn, module.lambdas.enricher_arn]
      },
      {
        Effect   = "Allow"
        Action   = ["dynamodb:PutItem", "dynamodb:UpdateItem"]
        Resource = aws_dynamodb_table.transactions.arn
      },
      {
        Effect   = "Allow"
        Action   = ["sns:Publish"]
        Resource = aws_sns_topic.fraud_alerts.arn
      },
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogDelivery", "logs:PutLogEvents", "logs:GetLogDelivery"]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["xray:PutTraceSegments", "xray:GetSamplingRules"]
        Resource = "*"
      }
    ]
  })
}
