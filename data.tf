############################################
# DEFAULT VPC + SUBNETS
############################################
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
 filter {
    name   = "availability-zone"
    values = ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d", "us-east-1f"]
  }
}

############################################
# AMAZON LINUX 2023 AMI FROM SSM
############################################
data "aws_ssm_parameter" "amazon_linux_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}
