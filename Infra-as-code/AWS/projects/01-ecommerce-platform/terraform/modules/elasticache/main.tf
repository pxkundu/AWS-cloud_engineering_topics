resource "aws_elasticache_subnet_group" "this" {
  name       = "${var.cluster_id}-subnet-group"
  subnet_ids = var.subnet_ids
}

resource "aws_security_group" "this" {
  name        = "${var.cluster_id}-sg"
  description = "ElastiCache Redis"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [var.allowed_sg_id]
  }
}

resource "aws_elasticache_replication_group" "this" {
  replication_group_id = var.cluster_id
  description          = "Redis cluster for ${var.cluster_id}"

  node_type            = var.node_type
  num_cache_clusters   = var.num_cache_nodes
  port                 = 6379
  parameter_group_name = "default.redis7"
  engine_version       = "7.1"

  subnet_group_name  = aws_elasticache_subnet_group.this.name
  security_group_ids = [aws_security_group.this.id]

  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  auth_token_enabled         = true

  automatic_failover_enabled = var.num_cache_nodes > 1
  multi_az_enabled           = var.num_cache_nodes > 1

  snapshot_retention_limit = 7
  snapshot_window          = "03:00-05:00"
  maintenance_window       = "sun:05:00-sun:07:00"

  log_delivery_configuration {
    destination      = "/elasticache/${var.cluster_id}/slow-logs"
    destination_type = "cloudwatch-logs"
    log_format       = "json"
    log_type         = "slow-log"
  }
}

variable "cluster_id"      { type = string }
variable "node_type"       { type = string }
variable "num_cache_nodes" { type = number }
variable "vpc_id"          { type = string }
variable "subnet_ids"      { type = list(string) }
variable "allowed_sg_id"   { type = string }

output "endpoint"          { value = aws_elasticache_replication_group.this.primary_endpoint_address }
output "reader_endpoint"   { value = aws_elasticache_replication_group.this.reader_endpoint_address }
