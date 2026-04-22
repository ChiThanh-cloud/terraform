############################################
# LOCALS
############################################
locals {
  db_name = "hospital_booking"
  db_port = 3306
  cors_origin = "https://${aws_cloudfront_distribution.app_cdn.domain_name}"
}

############################################
# USER DATA TEMPLATE
############################################
locals {
  user_data = templatefile("${path.module}/user_data.sh", {
    github_repo_url = var.github_repo_url
    db_host         = aws_db_instance.mysql.address
    db_port         = local.db_port
    db_name         = local.db_name
    db_username     = var.db_username
    db_password     = var.db_password
    app_port        = var.app_port
    cors_origin     = local.cors_origin
  })
}
