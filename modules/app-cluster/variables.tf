variable "name_prefix" {
  description = "Naming prefix: <project>-<environment>"
  type        = string
}

# ── Network inputs (from modules/network) ──────────────────
variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "List of public subnet IDs for ALB and ASG"
  type        = list(string)
}

variable "alb_sg_id" {
  description = "Security Group ID for ALB"
  type        = string
}

variable "ec2_sg_id" {
  description = "Security Group ID for EC2"
  type        = string
}

# ── IAM inputs (from modules/iam) ──────────────────────────
variable "instance_profile_name" {
  description = "IAM Instance Profile name to attach to EC2"
  type        = string
}

# ── Compute config ─────────────────────────────────────────
variable "ec2_instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "EC2 Key Pair name for SSH access"
  type        = string
}

variable "app_port" {
  description = "Port Nginx listens on (ALB target group port)"
  type        = number
  default     = 80
}

variable "asg_min_size" {
  description = "Minimum number of EC2 instances in ASG"
  type        = number
  default     = 1
}

variable "asg_max_size" {
  description = "Maximum number of EC2 instances in ASG"
  type        = number
  default     = 2
}

variable "asg_desired_capacity" {
  description = "Desired number of EC2 instances in ASG"
  type        = number
  default     = 1
}

# ── App / user_data inputs ─────────────────────────────────
variable "github_repo_url" {
  description = "Public GitHub repo URL to clone on EC2 startup"
  type        = string
}

variable "db_host" {
  description = "RDS endpoint hostname (from modules/database)"
  type        = string
}

variable "db_port" {
  description = "RDS port"
  type        = number
  default     = 3306
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "db_username" {
  description = "Database username"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "cors_origin" {
  description = "Allowed CORS origin (CloudFront URL or custom domain)"
  type        = string
}

variable "email_provider" {
  description = "Email provider: 'ses' or 'ethereal'"
  type        = string
  default     = "ses"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "ses_region" {
  description = "AWS SES region"
  type        = string
  default     = "us-east-1"
}

variable "email_from" {
  description = "Verified SES sender email"
  type        = string
}
