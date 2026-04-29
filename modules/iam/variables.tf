variable "name_prefix" {
  description = "Naming prefix: <project>-<environment>"
  type        = string
}

variable "ses_region" {
  description = "AWS SES region for email sending"
  type        = string
  default     = "us-east-1"
}

variable "email_from" {
  description = "Verified SES sender email identity"
  type        = string
}
