output "workshop_s3_bucket_website_url" {
  description = "The URL of the S3 bucket configured as a website"
  value       = aws_s3_bucket_website_configuration.workshop.website_endpoint
}

# Add other outputs here if needed
