# ALB Security Group — accepts HTTPS from internet
resource "aws_security_group" "alb" {
  name        = "${var.project}-${var.environment}-alb-sg"
  description = "ALB inbound HTTPS/HTTP"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ECS Security Group — accepts traffic only from ALB
resource "aws_security_group" "ecs" {
  name        = "${var.project}-${var.environment}-ecs-sg"
  description = "ECS tasks — inbound from ALB only"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# RDS Security Group — accepts traffic from ECS only
resource "aws_security_group" "rds" {
  name        = "${var.project}-${var.environment}-rds-sg"
  description = "RDS — inbound from ECS only"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
  }
}

# ElastiCache Security Group
resource "aws_security_group" "cache" {
  name        = "${var.project}-${var.environment}-cache-sg"
  description = "ElastiCache — inbound from ECS only"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
  }
}

variable "project"     { type = string }
variable "environment" { type = string }
variable "vpc_id"      { type = string }
variable "vpc_cidr"    { type = string }

output "alb_sg_id"   { value = aws_security_group.alb.id }
output "ecs_sg_id"   { value = aws_security_group.ecs.id }
output "rds_sg_id"   { value = aws_security_group.rds.id }
output "cache_sg_id" { value = aws_security_group.cache.id }
