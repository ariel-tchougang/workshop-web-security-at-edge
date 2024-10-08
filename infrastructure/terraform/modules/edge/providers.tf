terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  required_version = ">= 1.9.0"
}

provider "aws" {
  alias  = "us_east_1_region"
  region = "us-east-1"
}
