output "vpc_id" {
  description = "ID of the VPC"
  value       = data.aws_vpc.this.id
}

output "subnet_ids" {
  description = "List of public subnet IDs"
  value       = data.aws_subnets.this.ids
}

output "alb_sg_id" {
  description = "Security Group ID for the Application Load Balancer"
  value       = aws_security_group.alb.id
}

output "ec2_sg_id" {
  description = "Security Group ID for EC2 instances"
  value       = aws_security_group.ec2.id
}

output "rds_sg_id" {
  description = "Security Group ID for RDS MySQL"
  value       = aws_security_group.rds.id
}
