# ─────────────────────────────────────────────────────────
# environments/prod/terraform.tfvars
# Only NON-SENSITIVE values live here — safe to commit.
# All secrets (db_password, key_name, etc.) are stored in
# AWS SSM Parameter Store under /hospital/prod/...
# ─────────────────────────────────────────────────────────

aws_region   = "us-east-1"
project_name = "hospital-booking"
environment  = "prod"

# Network
app_port = 80

# Database
db_name                 = "hospital_booking"
db_instance_class       = "db.t3.micro"
db_allocated_storage    = 20
multi_az                = false
backup_retention_period = 7

# Compute
ec2_instance_type    = "t3.micro"
asg_min_size         = 1
asg_max_size         = 2
asg_desired_capacity = 1

# Email
email_provider = "ses"
ses_region     = "us-east-1"

# CDN & WAF
acm_certificate_arn = "arn:aws:acm:us-east-1:216938125549:certificate/2f1c625d-ad4c-426e-9bf2-94d26eee19ef"
custom_domain       = "nguyenchithanhit.id.vn"
enable_waf          = false
waf_rate_limit      = 1000

# CI/CD — GitHub OIDC
# Phải khớp chính xác với tên Repo trên GitHub (owner/repo-name)
github_terraform_repo = "Thanh123-ui/terraform"
tf_state_bucket       = "hospital-booking-tfstate"
tf_lock_table         = "hospital-booking-tflock"
