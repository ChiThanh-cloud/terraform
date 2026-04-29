############################################
# AMI — Amazon Linux 2023 (latest via SSM)
############################################
data "aws_ssm_parameter" "amazon_linux_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

############################################
# ALB TARGET GROUP
############################################
resource "aws_lb_target_group" "this" {
  name        = "${var.name_prefix}-tg"
  port        = var.app_port
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = var.vpc_id

  health_check {
    enabled             = true
    path                = "/health"
    protocol            = "HTTP"
    port                = tostring(var.app_port)
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = { Name = "${var.name_prefix}-tg" }
}

############################################
# APPLICATION LOAD BALANCER
############################################
resource "aws_lb" "this" {
  name               = "${var.name_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.subnet_ids

  tags = { Name = "${var.name_prefix}-alb" }
}

############################################
# ALB LISTENER
############################################
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

############################################
# EC2 LAUNCH TEMPLATE
############################################
resource "aws_launch_template" "this" {
  name_prefix   = "${var.name_prefix}-lt-"
  image_id      = data.aws_ssm_parameter.amazon_linux_ami.value
  instance_type = var.ec2_instance_type
  key_name      = var.key_name

  vpc_security_group_ids = [var.ec2_sg_id]

  iam_instance_profile {
    name = var.instance_profile_name
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    github_repo_url = var.github_repo_url
    db_host         = var.db_host
    db_port         = var.db_port
    db_name         = var.db_name
    db_username     = var.db_username
    db_password     = var.db_password
    app_port        = var.app_port
    cors_origin     = var.cors_origin
    email_provider  = var.email_provider
    aws_region      = var.aws_region
    ses_region      = var.ses_region
    email_from      = var.email_from
  }))

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = 20
      volume_type           = "gp2"
      delete_on_termination = true
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "${var.name_prefix}-asg-instance" }
  }

  tags = { Name = "${var.name_prefix}-lt" }
}

############################################
# AUTO SCALING GROUP
############################################
resource "aws_autoscaling_group" "this" {
  name                = "${var.name_prefix}-asg"
  min_size            = var.asg_min_size
  max_size            = var.asg_max_size
  desired_capacity    = var.asg_desired_capacity
  vpc_zone_identifier = var.subnet_ids
  health_check_type         = "ELB"
  health_check_grace_period = 180

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.this.arn]

  tag {
    key                 = "Name"
    value               = "${var.name_prefix}-asg-instance"
    propagate_at_launch = true
  }

  depends_on = [aws_lb_listener.http]
}
