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
    Name = join("-", ["WorkshopWebACL", var.suffix])
  }
}
