output "db_address" {
  description = "RDS endpoint hostname (used by EC2 app as DB_HOST)"
  value       = aws_db_instance.this.address
}

output "db_port" {
  description = "RDS port"
  value       = aws_db_instance.this.port
}

output "db_name" {
  description = "Database name"
  value       = aws_db_instance.this.db_name
}

output "db_instance_id" {
  description = "RDS instance identifier"
  value       = aws_db_instance.this.identifier
}
