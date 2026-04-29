output "cloudfront_domain" {
  description = "Default CloudFront domain name"
  value       = aws_cloudfront_distribution.this.domain_name
}

output "cloudfront_id" {
  description = "CloudFront Distribution ID (use to invalidate cache after deploy)"
  value       = aws_cloudfront_distribution.this.id
}

output "app_url" {
  description = "Production HTTPS URL"
  value       = "https://${aws_cloudfront_distribution.this.domain_name}"
}

output "waf_arn" {
  description = "WAF Web ACL ARN (null if WAF is disabled)"
  value       = var.enable_waf ? aws_wafv2_web_acl.this[0].arn : null
}
