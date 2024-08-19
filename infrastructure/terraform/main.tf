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

module "compute" {
  source = "./modules/compute"
  providers = {
    aws = aws.var_region
    tls = tls
  }

  region                     = var.region
  s3_bucket_arn              = module.s3.workshop_s3_bucket_arn
  s3_bucket_name             = module.s3.workshop_s3_bucket_name
  vpc_id                     = module.networking.vpc_id
  subnet_ids                 = module.networking.subnet_ids
  alb_security_group         = module.networking.external_http_sg
  workshop_zip_file_location = var.workshop_zip_file_location
  webserver_security_groups  = [module.networking.ssh_from_instance_connect_sg, module.networking.internal_vpc_http_sg]
  nat_gateway_id             = module.networking.workshop_nat_gateway_id
  ec2_instance_connect_id    = module.networking.ec2_instance_connect_id
  suffix                     = random_string.random.result
}

