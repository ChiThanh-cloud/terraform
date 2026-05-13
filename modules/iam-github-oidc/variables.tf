variable "name_prefix" {
  description = "Prefix used for naming AWS IAM resources, typically '<project>-<environment>'."
  type        = string
}

variable "github_repo" {
  description = "GitHub repository allowed to assume this role, in 'owner/repository' format. Example: ChiThanh-cloud/terraform."
  type        = string
}

variable "aws_region" {
  description = "AWS Region used to build ARNs for region-scoped resources such as the DynamoDB lock table."
  type        = string
  default     = "us-east-1"
}

variable "tf_state_bucket" {
  description = "S3 bucket name that stores the Terraform remote state."
  type        = string
}

variable "tf_lock_table" {
  description = "DynamoDB table name used for Terraform state locking."
  type        = string
}
