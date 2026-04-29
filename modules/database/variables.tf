variable "name_prefix" {
  description = "Naming prefix: <project>-<environment>"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the DB subnet group"
  type        = list(string)
}

variable "rds_sg_id" {
  description = "Security Group ID to attach to RDS instance"
  type        = string
}

variable "db_name" {
  description = "Name of the MySQL database to create"
  type        = string
  default     = "hospital_booking"
}

variable "db_username" {
  description = "MySQL master username"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "MySQL master password"
  type        = string
  sensitive   = true
}

variable "db_instance_class" {
  description = "RDS instance type"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 20
}

variable "multi_az" {
  description = "Enable Multi-AZ for high availability (recommended for prod)"
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "Number of days to retain automated backups (0 = disabled)"
  type        = number
  default     = 0
}
