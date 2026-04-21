output "cluster_name"  { value = aws_ecs_cluster.this.name }
output "cluster_arn"   { value = aws_ecs_cluster.this.arn }
output "alb_dns_name"  { value = aws_lb.this.dns_name }
output "alb_arn"       { value = aws_lb.this.arn }
output "service_name"  { value = aws_ecs_service.api.name }
