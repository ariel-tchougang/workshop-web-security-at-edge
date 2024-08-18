# random resource
resource "random_string" "random" {
  length  = 8
  special = false
  upper   = false
}

module "networking" {
  source = "./modules/networking"
  providers = {
    aws = aws.var_region
  }

  region   = var.region
  vpc_cidr = var.vpc_cidr
  suffix   = random_string.random.result
}

module "edge" {
  source = "./modules/edge"
  providers = {
    aws = aws.us_east_1
  }

  aws_local_profile = var.aws_local_profile
  suffix            = random_string.random.result
  exec_platform     = var.exec_platform
}

module "s3" {
  source = "./modules/s3"
  providers = {
    aws = aws.var_region
  }

  region            = var.region
  aws_local_profile = var.aws_local_profile
  suffix            = random_string.random.result
}

/* module "compute" {
  source = "./modules/compute"
  providers = {
    aws = aws
  }

  vpc_id     = module.networking.vpc_id
  subnet_ids = module.networking.subnet_ids
}
*/
