variable "name_prefix" {
  description = "Naming prefix: <project>-<environment>"
  type        = string
}

variable "alb_dns_name" {
  description = "DNS name of the ALB (CloudFront origin)"
  type        = string
}

variable "alb_arn" {
  description = "ARN of the ALB (for WAF association)"
  type        = string
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN (must be in us-east-1). Leave empty to use CloudFront default cert."
  type        = string
  default     = ""
}

variable "custom_domain" {
  description = "Custom domain alias for CloudFront (e.g. nguyenchithanhit.id.vn). Leave empty if not using custom domain."
  type        = string
  default     = ""
}

variable "enable_waf" {
  description = "Toggle WAF v2 on/off"
  type        = bool
  default     = false
}

variable "waf_rate_limit" {
  description = "Maximum requests per 5 minutes per IP before blocking"
  type        = number
  default     = 1000
}
