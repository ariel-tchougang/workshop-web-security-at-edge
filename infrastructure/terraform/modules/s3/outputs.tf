output "workshop_s3_bucket_website_url" {
  description = "The URL of the S3 bucket configured as a website"
  value       = aws_s3_bucket_website_configuration.workshop.website_endpoint
}

output "workshop_s3_bucket_arn" {
  description = "S3 Bucket ARN"
  value       = aws_s3_bucket.workshop_s3_bucket.arn
}

output "workshop_s3_bucket_name" {
  description = "S3 Bucket name"
  value       = aws_s3_bucket.workshop_s3_bucket.bucket
}
