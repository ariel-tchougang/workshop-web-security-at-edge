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

resource "terraform_data" "exec_unix" {
  count = lower(var.exec_platform) == "linux" || lower(var.exec_platform) == "macos" ? 1 : 0
  input = join("|", [
    aws_wafv2_web_acl.workshop_web_acl.name,
    aws_wafv2_web_acl.workshop_web_acl.id,
    aws_wafv2_web_acl.workshop_web_acl.visibility_config[0].metric_name,
    var.aws_local_profile
  ])

  depends_on = [
    aws_wafv2_web_acl.workshop_web_acl
  ]

  lifecycle {
    create_before_destroy = true
  }

  provisioner "local-exec" {
    command     = <<EOT
      sh "${path.module}/resources/update-web-acl.sh" "${self.input}"
    EOT
    when        = destroy
    interpreter = ["/bin/sh", "-c"]
  }
}

resource "terraform_data" "exec_windows" {
  count = lower(var.exec_platform) == "windows" ? 1 : 0
  input = join("|", [
    aws_wafv2_web_acl.workshop_web_acl.name,
    aws_wafv2_web_acl.workshop_web_acl.id,
    aws_wafv2_web_acl.workshop_web_acl.visibility_config[0].metric_name,
    var.aws_local_profile
  ])

  depends_on = [
    aws_wafv2_web_acl.workshop_web_acl
  ]

  lifecycle {
    create_before_destroy = true
  }

  provisioner "local-exec" {
    command     = <<EOT
      PowerShell -ExecutionPolicy Bypass -File "${path.module}/resources/update-web-acl.ps1" -InputParameter "${self.input}"
    EOT
    when        = destroy
    interpreter = ["PowerShell", "-Command"]
  }
}