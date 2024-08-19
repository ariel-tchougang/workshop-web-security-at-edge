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

variable "exec_platform" {
  description = "Execution platform"
  type        = string
  default     = "linux"

  validation {
    condition     = contains(["linux", "windows", "macos"], lower(var.exec_platform))
    error_message = "Execution platform must be 'linux', 'windows', or 'macos'."
  }
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

variable "workshop_zip_file_location" {
  description = "Workshop web files source URL"
  type        = string
  default     = "https://github.com/ariel-tchougang/workshop-web-security-at-edge/archive/refs/heads/main.zip"

  validation {
    condition     = can(regex("^https?://.*\\.zip$", var.workshop_zip_file_location))
    error_message = "Must be an http url pointing to a zip file"
  }
}
