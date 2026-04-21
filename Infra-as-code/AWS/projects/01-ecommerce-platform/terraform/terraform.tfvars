# Production values — override per environment
project     = "ecommerce"
environment = "prod"
aws_region  = "us-east-1"

vpc_cidr           = "10.0.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]

public_subnet_cidrs   = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
private_subnet_cidrs  = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
database_subnet_cidrs = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]

db_instance_class = "db.r6g.large"
db_instance_count = 3
cache_node_type   = "cache.r6g.large"

# Set via CI/CD environment variables
# ecr_repo_url    = "123456789.dkr.ecr.us-east-1.amazonaws.com/ecommerce"
# image_tag       = "v1.2.3"
# certificate_arn = "arn:aws:acm:us-east-1:123456789:certificate/abc-123"
