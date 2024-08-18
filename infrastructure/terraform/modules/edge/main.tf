resource "aws_wafv2_web_acl" "workshop_web_acl" {
  name        = join("-", ["WorkshopWebACL", var.suffix])
  scope       = "CLOUDFRONT"
  description = "Workshop WebACL"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = join("-", ["WorkshopWebACLMetric", var.suffix])
    sampled_requests_enabled   = true
  }

  tags = {
    Name    = join("-", ["WorkshopWebACL", var.suffix])
    Profile = var.aws_local_profile
  }

  # Provisioner for Unix-based systems (Linux and macOS)
  # provisioner "local-exec" {
  #   command = <<EOT
  #     lock_token=$(aws wafv2 get-web-acl --name ${self.name} --scope CLOUDFRONT --region us-east-1 --id ${self.id} --query LockToken --output text --profile ${self.tags.Profile})
  #     aws wafv2 update-web-acl --name ${self.name} --scope CLOUDFRONT --region us-east-1 --id ${self.id} --lock-token $lock_token --default-action '{"Allow": {}}' --visibility-config '{"SampledRequestsEnabled": true, "CloudWatchMetricsEnabled": true, "MetricName": "${self.visibility_config[0].metric_name}"}' --rules '[]' --profile ${self.tags.Profile}
  #   EOT
  #   when    = destroy
  #   interpreter = ["/bin/sh", "-c"]
  # }

  # Provisioner for Windows systems
  provisioner "local-exec" {
    command     = <<EOT
      $lock_token = aws wafv2 get-web-acl --name ${self.name} --scope CLOUDFRONT --region us-east-1 --id ${self.id} --query LockToken --output text --profile ${self.tags.Profile};
      aws wafv2 update-web-acl --name ${self.name} --scope CLOUDFRONT --region us-east-1 --id ${self.id} --lock-token $lock_token --default-action '{\"Allow\": {}}' --visibility-config '{\"SampledRequestsEnabled\": true, \"CloudWatchMetricsEnabled\": true, \"MetricName\": \"${self.visibility_config[0].metric_name}\"}' --rules '[]' --profile ${self.tags.Profile};
    EOT
    when        = destroy
    interpreter = ["PowerShell", "-Command"]
  }
}
