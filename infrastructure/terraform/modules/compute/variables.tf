variable "region" {
  description = "AWS region for networking resources"
  type        = string
}

variable "suffix" {
  description = "Suffix to append to resource names"
  type        = string
}

variable "s3_bucket_arn" {
  description = "Workshop S3 bucket ARN"
  type        = string
}

variable "s3_bucket_name" {
  description = "Workshop S3 bucket name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs"
  type        = list(string)
}

variable "alb_security_group" {
  description = "ALB security group"
  type        = string
}

variable "webserver_security_groups" {
  description = "List of security groups IDs"
  type        = list(string)
}

variable "workshop_zip_file_location" {
  description = "Workshop web files source URL"
  type        = string
  default     = "https://github.com/ariel-tchougang/workshop-web-security-at-edge/archive/refs/heads/main.zip"

  validation {
    condition     = can(regex("^https?://.*\\.zip$", var.workshop_zip_file_location))
    error_message = "Must be an http url pointing to a zip file"
  }
}

variable "nat_gateway_id" {
  description = "NAT Gateway ID"
  type        = string
}

variable "ec2_instance_connect_id" {
  description = "EC2 Instance Connect Endpoint ID"
  type        = string
}
