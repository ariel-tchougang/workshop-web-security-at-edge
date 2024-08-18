variable "suffix" {
  description = "Suffix to append to resource names"
  type        = string
  default     = "workshop"
}

variable "aws_local_profile" {
  description = "AWS local exec profile"
  type        = string
  default     = "terraform-role"
}

# Define other variables if needed

