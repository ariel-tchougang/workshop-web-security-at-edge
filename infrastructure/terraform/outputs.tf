output "vpc_id" {
  description = "Workshop VPC ID"
  value       = module.networking.vpc_id
}

output "subnet_ids" {
  description = "Workshop VPC subbets IDs"
  value       = module.networking.subnet_ids
}

output "s3_bucket_website_url" {
  description = "The URL of the S3 bucket configured as a website"
  value       = join("", ["http://", module.s3.workshop_s3_bucket_website_url])
}

output "s3_bucket_name" {
  description = "The name of the S3 bucket configured as a website"
  value       = module.s3.workshop_s3_bucket_name
}

output "workshop_webserver_id" {
  description = "Workshop Webserver instance ID"
  value       = module.compute.workshop_webserver_id
}

output "workshop_load_balancer_dns_name" {
  description = "The DNS name of the Workshop Load Balancer"
  value       = join("", ["http://", module.compute.workshop_load_balancer_dns_name])
}

# output "rendered_user_data" {
#   value = module.compute.rendered_user_data
# }

