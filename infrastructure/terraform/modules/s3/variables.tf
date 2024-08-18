variable "region" {
  description = "AWS region for S3 bucket"
  type        = string
}

variable "aws_local_profile" {
  description = "AWS local exec profile"
  type        = string
  default     = "terraform-role"
}

variable "suffix" {
  description = "Suffix to append to resource names"
  type        = string
  default     = "workshop"
}




