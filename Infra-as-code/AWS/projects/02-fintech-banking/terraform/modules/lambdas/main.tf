locals {
  functions = {
    stream-processor = { handler = "handler.main", timeout = 60,  memory = 512  }
    fraud-detector   = { handler = "handler.main", timeout = 30,  memory = 256  }
    enricher         = { handler = "handler.main", timeout = 30,  memory = 256  }
    notifier         = { handler = "handler.main", timeout = 15,  memory = 128  }
  }
}

# Shared Lambda security group
resource "aws_security_group" "lambda" {
  name        = "${var.project}-${var.environment}-lambda-sg"
  description = "Lambda functions outbound"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# IAM execution role
resource "aws_iam_role" "lambda" {
  name = "${var.project}-${var.environment}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "vpc_access" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy" "lambda" {
  role = aws_iam_role.lambda.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["dynamodb:PutItem", "dynamodb:GetItem", "dynamodb:UpdateItem", "dynamodb:Query"]
        Resource = ["arn:aws:dynamodb:*:*:table/${var.table_name}", "arn:aws:dynamodb:*:*:table/${var.table_name}/index/*"]
      },
      {
        Effect   = "Allow"
        Action   = ["kinesis:GetRecords", "kinesis:GetShardIterator", "kinesis:DescribeStream", "kinesis:ListShards"]
        Resource = var.stream_arn
      },
      {
        Effect   = "Allow"
        Action   = ["states:StartExecution"]
        Resource = var.sfn_arn
      },
      {
        Effect   = "Allow"
        Action   = ["kms:Decrypt", "kms:GenerateDataKey"]
        Resource = var.kms_key_arn
      },
      {
        Effect   = "Allow"
        Action   = ["xray:PutTraceSegments", "xray:PutTelemetryRecords"]
        Resource = "*"
      }
    ]
  })
}

# CloudWatch log groups
resource "aws_cloudwatch_log_group" "functions" {
  for_each          = local.functions
  name              = "/aws/lambda/${var.project}-${var.environment}-${each.key}"
  retention_in_days = 90
  kms_key_id        = var.kms_key_arn
}

# Lambda functions
resource "aws_lambda_function" "functions" {
  for_each = local.functions

  function_name = "${var.project}-${var.environment}-${each.key}"
  role          = aws_iam_role.lambda.arn
  handler       = each.value.handler
  runtime       = "python3.11"
  timeout       = each.value.timeout
  memory_size   = each.value.memory

  # Placeholder — replace with actual deployment package
  filename         = "${path.module}/placeholder.zip"
  source_code_hash = filebase64sha256("${path.module}/placeholder.zip")

  environment {
    variables = {
      TABLE_NAME  = var.table_name
      ENVIRONMENT = var.environment
      POWERTOOLS_SERVICE_NAME = "${var.project}-${each.key}"
      LOG_LEVEL   = "INFO"
    }
  }

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = [aws_security_group.lambda.id]
  }

  tracing_config { mode = "Active" }

  dead_letter_config {
    target_arn = aws_sqs_queue.dlq[each.key].arn
  }

  depends_on = [aws_cloudwatch_log_group.functions]
}

# DLQs per function
resource "aws_sqs_queue" "dlq" {
  for_each                  = local.functions
  name                      = "${var.project}-${var.environment}-${each.key}-dlq"
  message_retention_seconds = 1209600  # 14 days
  kms_master_key_id         = var.kms_key_arn
}

# Kinesis trigger for stream-processor
resource "aws_lambda_event_source_mapping" "kinesis" {
  event_source_arn              = var.stream_arn
  function_name                 = aws_lambda_function.functions["stream-processor"].arn
  starting_position             = "LATEST"
  batch_size                    = 100
  bisect_batch_on_function_error = true
  maximum_retry_attempts        = 3

  destination_config {
    on_failure {
      destination_arn = aws_sqs_queue.dlq["stream-processor"].arn
    }
  }
}

variable "project"     { type = string }
variable "environment" { type = string }
variable "vpc_id"      { type = string }
variable "subnet_ids"  { type = list(string) }
variable "kms_key_arn" { type = string }
variable "table_name"  { type = string }
variable "stream_arn"  { type = string }
variable "sfn_arn"     { type = string }

output "fraud_detector_arn" { value = aws_lambda_function.functions["fraud-detector"].arn }
output "enricher_arn"       { value = aws_lambda_function.functions["enricher"].arn }
output "notifier_arn"       { value = aws_lambda_function.functions["notifier"].arn }
