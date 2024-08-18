variable "region" {
  description = "AWS region for networking, compute, and S3 modules"
  type        = string
  default     = "us-east-1"
}

variable "aws_local_profile" {
  description = "AWS local exec profile"
  type        = string
  default     = "terraform-role"
}

variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}/[0-9]{1,2}$", var.vpc_cidr)) && length(regexall("^([0-9]{1,3}\\.){3}[0-9]{1,3}/[0-9]{1,2}$", var.vpc_cidr)) > 0
    error_message = "The CIDR block must be in a valid format (e.g., 10.0.0.0/16)."
  }
}
