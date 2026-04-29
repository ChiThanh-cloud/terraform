output "app_url" {
  description = "Production HTTPS URL (custom domain)"
  value       = "https://${var.custom_domain}"
}

output "cloudfront_domain" {
  description = "Default CloudFront domain"
  value       = module.cdn_waf.cloudfront_domain
}

output "cloudfront_id" {
  description = "CloudFront Distribution ID"
  value       = module.cdn_waf.cloudfront_id
}

output "alb_url" {
  description = "Direct ALB HTTP URL (for debugging)"
  value       = module.app_cluster.alb_url
}

output "rds_endpoint" {
  description = "RDS MySQL endpoint (internal VPC)"
  value       = module.database.db_address
  sensitive   = true
}

output "asg_name" {
  description = "Auto Scaling Group name"
  value       = module.app_cluster.asg_name
}
