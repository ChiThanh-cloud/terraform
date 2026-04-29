variable "name_prefix" {
  description = "Naming prefix: <project>-<environment>"
  type        = string
}

variable "app_port" {
  description = "Port the application (Nginx) listens on. ALB forwards to this port."
  type        = number
  default     = 80
}

variable "availability_zones" {
  description = "List of AZs to filter subnets from"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d", "us-east-1f"]
}
