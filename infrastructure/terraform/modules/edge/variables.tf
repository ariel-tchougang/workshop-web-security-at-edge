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

variable "exec_platform" {
  description = "Execution platform"
  type        = string
  default     = "linux"

  validation {
    condition     = contains(["linux", "windows", "macos"], lower(var.exec_platform))
    error_message = "Execution platform must be 'linux', 'windows', or 'macos'."
  }
}

