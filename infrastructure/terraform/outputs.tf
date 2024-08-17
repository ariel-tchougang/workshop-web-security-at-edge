output "vpc_id" {
  value = module.networking.vpc_id
}

output "subnet_ids" {
  value = module.networking.subnet_ids
}

output "s3_bucket_website_url" {
  description = "The URL of the S3 bucket configured as a website"
  value       = module.s3.workshop_s3_bucket_website_url
}