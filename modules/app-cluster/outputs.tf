output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer (used by cdn-waf module)"
  value       = aws_lb.this.dns_name
}

output "alb_arn" {
  description = "ARN of the ALB (used by WAF association)"
  value       = aws_lb.this.arn
}

output "alb_url" {
  description = "HTTP URL via ALB (for debugging)"
  value       = "http://${aws_lb.this.dns_name}"
}

output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.this.name
}

output "target_group_arn" {
  description = "ARN of the ALB Target Group"
  value       = aws_lb_target_group.this.arn
}
