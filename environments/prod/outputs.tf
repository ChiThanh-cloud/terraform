############################################
# CI/CD - GITHUB OIDC OUTPUTS
############################################
output "github_actions_role_arn" {
  description = "ARN của IAM Role - COPY DÒNG NÀY DÁN VÀO GITHUB SECRETS (AWS_ROLE_ARN)"
  value       = module.github_oidc.github_actions_role_arn
}

############################################
# NETWORK OUTPUTS
############################################
output "vpc_id" {
  value = module.network.vpc_id
}

############################################
# DATABASE OUTPUTS
############################################
output "db_address" {
  value = module.database.db_address
}

############################################
# APP CLUSTER OUTPUTS
############################################
output "alb_dns_name" {
  value = module.app_cluster.alb_dns_name
}

############################################
# CDN OUTPUTS
############################################
output "cloudfront_domain" {
  value = module.cdn_waf.cloudfront_domain
}
