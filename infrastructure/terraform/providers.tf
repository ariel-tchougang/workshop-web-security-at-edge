terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  required_version = ">= 1.9.0"
}

provider "aws" {
  alias                    = "deployment_region"
  region                   = var.region
  shared_config_files      = ["~/.aws/config"]
  shared_credentials_files = ["~/.aws/credentials"]
  profile                  = var.aws_local_profile
}

provider "aws" {
  alias                    = "us_east_1_region"
  region                   = "us-east-1"
  shared_config_files      = ["~/.aws/config"]
  shared_credentials_files = ["~/.aws/credentials"]
  profile                  = var.aws_local_profile
}

provider "tls" {}