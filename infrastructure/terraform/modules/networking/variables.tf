variable "region" {
  description = "AWS region for networking resources"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "suffix" {
  description = "Suffix to append to resource names"
  type        = string
  default     = "workshop"
}

locals {
  all_ipv4_cidr = "0.0.0.0/0"
}
