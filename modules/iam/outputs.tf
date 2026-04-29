output "instance_profile_name" {
  description = "Name of the IAM Instance Profile to attach to EC2 Launch Template"
  value       = aws_iam_instance_profile.this.name
}

output "role_arn" {
  description = "ARN of the EC2 IAM Role"
  value       = aws_iam_role.this.arn
}

output "role_name" {
  description = "Name of the EC2 IAM Role"
  value       = aws_iam_role.this.name
}
