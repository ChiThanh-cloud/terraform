############################################
# GLOBAL
############################################
variable "aws_region" {
  description = "AWS deployment region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name prefix used for all resource names"
  type        = string
  default     = "hospital-booking"
}

variable "environment" {
  description = "Deployment environment (dev / staging / prod)"
  type        = string
  default     = "prod"
}

############################################
# NETWORK
############################################
variable "availability_zones" {
  description = "AZs to filter subnets from"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "app_port" {
  description = "Port Nginx listens on (ALB target group port)"
  type        = number
  default     = 80
}

############################################
# DATABASE
############################################
variable "db_name" {
  description = "Name of the MySQL database"
  type        = string
  default     = "hospital_booking"
}

variable "db_instance_class" {
  description = "RDS instance type"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Allocated storage for RDS in GB"
  type        = number
  default     = 20
}

variable "multi_az" {
  description = "Enable Multi-AZ RDS deployment"
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "Number of days to retain RDS backups"
  type        = number
  default     = 7
}

############################################
# COMPUTE
############################################
variable "ec2_instance_type" {
  description = "EC2 instance type for app servers"
  type        = string
  default     = "t3.micro"
}

variable "asg_min_size" {
  description = "Minimum EC2 instances in ASG"
  type        = number
  default     = 1
}

variable "asg_max_size" {
  description = "Maximum EC2 instances in ASG"
  type        = number
  default     = 2
}

variable "asg_desired_capacity" {
  description = "Desired EC2 instances in ASG"
  type        = number
  default     = 1
}

############################################
# EMAIL
############################################
variable "email_provider" {
  description = "Email provider: 'ses' or 'ethereal'"
  type        = string
  default     = "ses"
}

variable "ses_region" {
  description = "AWS SES sending region"
  type        = string
  default     = "us-east-1"
}

############################################
# CDN & WAF
############################################
variable "acm_certificate_arn" {
  description = "ACM certificate ARN in us-east-1 for CloudFront HTTPS"
  type        = string
  default     = "arn:aws:acm:us-east-1:216938125549:certificate/2f1c625d-ad4c-426e-9bf2-94d26eee19ef"
}

variable "custom_domain" {
  description = "Custom domain alias for CloudFront"
  type        = string
  default     = "nguyenchithanhit.id.vn"
}

variable "enable_waf" {
  description = "Toggle WAF v2 on/off"
  type        = bool
  default     = false
}

variable "waf_rate_limit" {
  description = "Requests per 5 minutes per IP before WAF blocks"
  type        = number
  default     = 1000
}

############################################
# CI/CD — GitHub OIDC
############################################
variable "github_terraform_repo" {
  description = "GitHub repository authorized to run Terraform through OIDC, in 'owner/repository' format. Example: ChiThanh-cloud/terraform."
  type        = string
  default     = "ChiThanh-cloud/terraform"
}

variable "tf_state_bucket" {
  description = "S3 bucket name used for Terraform remote state. Must match the backend configuration."
  type        = string
  default     = "hospital-booking-tfstate"
}

variable "tf_lock_table" {
  description = "DynamoDB table name used for Terraform state locking. Must match the backend configuration."
  type        = string
  default     = "hospital-booking-tflock"
}
