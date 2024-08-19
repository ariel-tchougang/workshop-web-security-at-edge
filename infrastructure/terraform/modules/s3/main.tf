resource "aws_s3_bucket" "workshop_s3_bucket" {
  bucket = join("-", ["workshop-edge-protection-s3-bucket", var.suffix])

  tags = {
    Name    = join("-", ["workshop-edge-protection-s3-bucket", var.suffix])
    Profile = var.aws_local_profile
  }

  provisioner "local-exec" {
    command = <<EOT
      aws s3 rm s3://${self.bucket} --recursive --profile ${self.tags.Profile}
    EOT
    when    = destroy
  }
}

resource "aws_s3_bucket_public_access_block" "workshop" {
  bucket = aws_s3_bucket.workshop_s3_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_ownership_controls" "workshop" {
  bucket = aws_s3_bucket.workshop_s3_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "workshop" {
  depends_on = [aws_s3_bucket_ownership_controls.workshop]
  bucket     = aws_s3_bucket.workshop_s3_bucket.id
  acl        = "private"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "workshop" {
  bucket = aws_s3_bucket.workshop_s3_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_website_configuration" "workshop" {
  bucket = aws_s3_bucket.workshop_s3_bucket.id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_policy" "workshop_s3_bucket_policy" {
  bucket = aws_s3_bucket.workshop_s3_bucket.id
  policy = data.aws_iam_policy_document.workshop_s3_bucket_policy.json

  depends_on = [
    aws_s3_bucket_acl.workshop,
    aws_s3_bucket_ownership_controls.workshop
  ]
}

data "aws_iam_policy_document" "workshop_s3_bucket_policy" {
  statement {
    sid    = "AllowPublicReadAccess"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.workshop_s3_bucket.arn}/*"]
  }
}

