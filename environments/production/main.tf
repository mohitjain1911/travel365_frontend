locals {
  name = "${var.app_name}-${var.environment}"
}

module "vpc" {
  source               = "../../modules/vpc"
  name                 = local.name
  cidr                 = "10.0.0.0/16"
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  enable_nat           = var.enable_nat
  region               = "eu-west-2"
}

resource "aws_security_group" "ecs" {
  name        = "${local.name}-ecs-sg"
  vpc_id      = module.vpc.vpc_id
  description = "Allow app traffic"
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = []
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "alb" {
  name   = "${local.name}-alb-sg"
  vpc_id = module.vpc.vpc_id
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

module "s3" {
  source      = "../../modules/s3"
  bucket_name = "${local.name}-assets-${random_id.bucket_hex.hex}"
  name        = "${local.name}-assets"
}

resource "random_id" "bucket_hex" { byte_length = 3 }

module "iam" {
  source    = "../../modules/iam"
  name      = local.name
  s3_bucket = module.s3.bucket
}

# Secrets - create DB secret and other app secrets
locals {
  db_secret = jsonencode({
    username = var.db_username
    password = var.db_password != "" ? var.db_password : random_password.db.result
  })
}

resource "random_password" "db" { length = 16 }

module "secrets_db" {
  source        = "../../modules/secrets"
  name          = "${local.name}-db"
  secret_string = local.db_secret
}

# RDS (enabled in prod only)
module "rds" {
  source                 = "../../modules/rds"
  db_name                = "${local.name}-db"
  username               = var.db_username
  password               = var.db_password != "" ? var.db_password : random_password.db.result
  instance_class         = "db.t3.micro"
  subnet_ids             = module.vpc.private_subnet_ids
  vpc_security_group_ids = [aws_security_group.ecs.id]
  depends_on             = [module.vpc]
}

# ElastiCache (Redis)
resource "aws_security_group" "redis" {
  name   = "${local.name}-redis-sg"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

module "redis" {
  source      = "../../modules/elasticache"
  name        = local.name
  subnet_ids  = module.vpc.private_subnet_ids
  redis_sg_id = aws_security_group.redis.id
  node_type   = "cache.t4g.micro"
}

# ECS cluster and services (images from variables)
module "ecs" {
  source                 = "../../modules/ecs"
  name                   = local.name
  cluster_name           = "${local.name}-cluster"
  backend_image          = var.backend_image
  frontend_image         = var.frontend_image
  admin_image            = var.admin_image
  subnet_ids             = module.vpc.private_subnet_ids
  security_groups        = [aws_security_group.ecs.id]
  execution_role_arn     = module.iam.ecs_task_exec_role_arn
  task_role_arn          = module.iam.ecs_task_role_arn
  backend_desired_count  = 2
  frontend_desired_count = 2
  admin_desired_count    = 1
}

# ALB (create basic ALB)
module "alb" {
  source             = "../../modules/alb"
  name               = local.name
  public_subnet_ids  = module.vpc.public_subnet_ids
  vpc_id             = module.vpc.vpc_id
  security_group_ids = [aws_security_group.alb.id]
  target_groups = {
    backend  = { port = 8080, tg_name = "${local.name}-backend-tg", health_path = "/health" }
    frontend = { port = 80, tg_name = "${local.name}-frontend-tg", health_path = "/" }
  }
}

# CloudFront & Route53 optional: create only if domain and create_hosted_zone true
module "route53_acm" {
  source             = "../../modules/route53_acm"
  domain_name        = var.domain_name
  create_hosted_zone = var.create_hosted_zone
  region             = "eu-west-2"
}

# Create ACM cert in us-east-1 for CloudFront (validated via Route53 hosted zone)
module "acm_us_east" {
  source         = "../../modules/acm-us-east-1"
  providers      = { aws = aws.us_east_1 }
  domain_name    = var.domain_name
  hosted_zone_id = try(module.route53_acm.hosted_zone_id, "")
  create_cert    = var.create_hosted_zone
}

# ECR repositories for services
module "ecr_backend" {
  source = "../../modules/ecr"
  name   = "${local.name}-backend"
}

module "ecr_frontend" {
  source = "../../modules/ecr"
  name   = "${local.name}-frontend"
}

module "ecr_admin" {
  source = "../../modules/ecr"
  name   = "${local.name}-admin"
}

# SES for domain (optional)
module "ses" {
  source         = "../../modules/ses"
  domain_name    = var.domain_name
  hosted_zone_id = try(module.route53_acm.hosted_zone_id, "")
  enabled        = var.enable_ses
}

# Basic WAF
module "waf" {
  source = "../../modules/waf"
  name   = "${local.name}-waf"
  scope  = "REGIONAL"
}

# SQS only in production (optional)
module "sqs" {
  source = "../../modules/sqs"
  count  = var.enable_sqs ? 1 : 0
  name   = "${local.name}-queue"
}

module "cloudfront" {
  source           = "../../modules/cloudfront"
  name             = local.name
  s3_bucket_origin = module.s3.bucket
  acm_cert_arn     = var.create_hosted_zone ? try(module.acm_us_east.acm_cert_arn, "") : ""
  domain_name      = var.domain_name
}

# Outputs
output "ecs_cluster_arn" { value = module.ecs.cluster_arn }
output "s3_bucket" { value = module.s3.bucket }
output "rds_endpoint" { value = module.rds.endpoint }
output "redis_endpoint" { value = module.redis.primary_endpoint_address }
