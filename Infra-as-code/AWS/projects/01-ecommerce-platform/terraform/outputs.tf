output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "alb_dns_name" {
  description = "Application Load Balancer DNS"
  value       = module.ecs.alb_dns_name
}

output "cloudfront_domain" {
  description = "CloudFront distribution domain"
  value       = module.cdn.cloudfront_domain
}

output "db_cluster_endpoint" {
  description = "Aurora writer endpoint"
  value       = module.aurora.cluster_endpoint
  sensitive   = true
}

output "db_reader_endpoint" {
  description = "Aurora reader endpoint"
  value       = module.aurora.cluster_reader_endpoint
  sensitive   = true
}

output "redis_endpoint" {
  description = "ElastiCache Redis endpoint"
  value       = module.elasticache.endpoint
  sensitive   = true
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = module.ecs.cluster_name
}
