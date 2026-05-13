############################################
# DATA SOURCES — SSM Secrets
############################################
data "aws_ssm_parameter" "db_password" {
  name            = "/hospital/${var.environment}/db_password"
  with_decryption = true
}

data "aws_ssm_parameter" "db_username" {
  name = "/hospital/${var.environment}/db_username"
}

data "aws_ssm_parameter" "key_name" {
  name = "/hospital/${var.environment}/key_name"
}

data "aws_ssm_parameter" "github_repo_url" {
  name = "/hospital/${var.environment}/github_repo_url"
}

data "aws_ssm_parameter" "email_from" {
  name = "/hospital/${var.environment}/email_from"
}

############################################
# LOCAL VALUES
############################################
locals {
  name_prefix = "${var.project_name}-${var.environment}"
  # Dùng "*" làm fallback thay vì module.cdn_waf.cloudfront_domain để tránh lỗi vòng lặp (Dependency Cycle)
  cors_origin = var.custom_domain != "" ? "https://${var.custom_domain}" : "*"
}

############################################
# LAYER 1 — NETWORK
############################################
module "network" {
  source = "../../modules/network"

  name_prefix        = local.name_prefix
  app_port           = var.app_port
  availability_zones = var.availability_zones
}

############################################
# LAYER 2 — IAM
############################################
module "iam" {
  source = "../../modules/iam"

  name_prefix = local.name_prefix
  ses_region  = var.ses_region
  email_from  = data.aws_ssm_parameter.email_from.value
}

############################################
# LAYER 3 — DATABASE
############################################
module "database" {
  source = "../../modules/database"

  name_prefix             = local.name_prefix
  subnet_ids              = module.network.subnet_ids
  rds_sg_id               = module.network.rds_sg_id
  db_name                 = var.db_name
  db_username             = data.aws_ssm_parameter.db_username.value
  db_password             = data.aws_ssm_parameter.db_password.value
  db_instance_class       = var.db_instance_class
  db_allocated_storage    = var.db_allocated_storage
  multi_az                = var.multi_az
  backup_retention_period = var.backup_retention_period
}

############################################
# LAYER 4 — APP CLUSTER (ALB + EC2 + ASG)
############################################
module "app_cluster" {
  source = "../../modules/app-cluster"

  name_prefix           = local.name_prefix
  vpc_id                = module.network.vpc_id
  subnet_ids            = module.network.subnet_ids
  alb_sg_id             = module.network.alb_sg_id
  ec2_sg_id             = module.network.ec2_sg_id
  instance_profile_name = module.iam.instance_profile_name
  ec2_instance_type     = var.ec2_instance_type
  key_name              = data.aws_ssm_parameter.key_name.value
  app_port              = var.app_port
  asg_min_size          = var.asg_min_size
  asg_max_size          = var.asg_max_size
  asg_desired_capacity  = var.asg_desired_capacity
  github_repo_url       = data.aws_ssm_parameter.github_repo_url.value
  db_host               = module.database.db_address
  db_port               = module.database.db_port
  db_name               = module.database.db_name
  db_username           = data.aws_ssm_parameter.db_username.name
  db_password           = data.aws_ssm_parameter.db_password.name
  cors_origin           = local.cors_origin
  email_provider        = var.email_provider
  aws_region            = var.aws_region
  ses_region            = var.ses_region
  email_from            = data.aws_ssm_parameter.email_from.value

  depends_on = [module.database]
}

############################################
# LAYER 5 — CDN + WAF
############################################
module "cdn_waf" {
  source = "../../modules/cdn-waf"

  name_prefix         = local.name_prefix
  alb_dns_name        = module.app_cluster.alb_dns_name
  alb_arn             = module.app_cluster.alb_arn
  acm_certificate_arn = var.acm_certificate_arn
  custom_domain       = var.custom_domain
  enable_waf          = var.enable_waf
  waf_rate_limit      = var.waf_rate_limit

  depends_on = [module.app_cluster]
}

############################################
# LAYER 6 — CI/CD: GitHub Actions OIDC
# Tạo kết nối tin tưởng giữa GitHub và AWS
# Không cần Access Key — an toàn nhất hiện nay
############################################
module "github_oidc" {
  source = "../../modules/iam-github-oidc"

  name_prefix     = local.name_prefix
  github_repo     = var.github_terraform_repo
  aws_region      = var.aws_region
  tf_state_bucket = var.tf_state_bucket
  tf_lock_table   = var.tf_lock_table
}

