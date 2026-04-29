############################################
# DB SUBNET GROUP
############################################
resource "aws_db_subnet_group" "this" {
  name       = "${var.name_prefix}-db-subnet-group"
  subnet_ids = var.subnet_ids

  tags = { Name = "${var.name_prefix}-db-subnet-group" }
}

############################################
# RDS MYSQL 8.0
############################################
resource "aws_db_instance" "this" {
  identifier     = "${var.name_prefix}-mysql"
  engine         = "mysql"
  engine_version = "8.0"

  instance_class    = var.db_instance_class
  allocated_storage = var.db_allocated_storage
  storage_type      = "gp2"

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password
  port     = 3306

  publicly_accessible     = false
  multi_az                = var.multi_az
  skip_final_snapshot     = true
  deletion_protection     = false
  apply_immediately       = true
  backup_retention_period = var.backup_retention_period

  vpc_security_group_ids = [var.rds_sg_id]
  db_subnet_group_name   = aws_db_subnet_group.this.name

  tags = { Name = "${var.name_prefix}-mysql" }
}
