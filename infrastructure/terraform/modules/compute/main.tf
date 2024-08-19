# AMI ID
data "aws_ssm_parameter" "ami_id" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-6.1-x86_64"
}

# RSA Key Pair
resource "tls_private_key" "rsa_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = join("-", ["workshop-key-pair", var.suffix])
  public_key = tls_private_key.rsa_key.public_key_openssh

  tags = {
    Name = join("-", ["workshop-key-pair", var.suffix])
  }
}

# EC2 Instance Profile
resource "aws_iam_role" "workshop_web_server_instance_role" {
  name = join("-", ["WorkshopWebServerInstanceRole", var.suffix])

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = "sts:AssumeRole",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  inline_policy {
    name = "AllowS3SyncPolicy"
    policy = jsonencode({
      Version = "2012-10-17",
      Statement = [
        {
          Effect = "Allow",
          Action = [
            "s3:DeleteObject",
            "s3:GetBucketLocation",
            "s3:GetObject",
            "s3:ListBucket",
            "s3:PutObject"
          ],
          Resource = [
            "${var.s3_bucket_arn}",
            "${var.s3_bucket_arn}/*"
          ]
        }
      ]
    })
  }

  inline_policy {
    name = "AllowTargetGroupRegistration"
    policy = jsonencode({
      Version = "2012-10-17",
      Statement = [
        {
          Effect = "Allow",
          Action = [
            "elasticloadbalancing:RegisterTargets",
            "elasticloadbalancing:DeregisterTargets",
            "elasticloadbalancing:DescribeTargetHealth"
          ],
          Resource = "*"
        }
      ]
    })
  }

  tags = {
    Name = join("-", ["WorkshopWebServerInstanceRole", var.suffix])
  }
}

resource "aws_iam_instance_profile" "workshop_web_server_instance_profile" {
  name = join("-", ["WorkshopWebServerInstanceProfile", var.suffix])
  role = aws_iam_role.workshop_web_server_instance_role.name
}

# ALB features

resource "aws_lb_target_group" "workshop_target_group" {
  name        = join("-", ["WorkshopTargetGroup", var.suffix])
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    interval            = 30
    path                = "/"
    port                = "80"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
    matcher             = "200"
  }

  tags = {
    Name = join("-", ["WorkshopTargetGroup", var.suffix])
  }
}

resource "aws_lb" "workshop_load_balancer" {
  name               = join("-", ["WorkshopLoadBalancer", var.suffix])
  internal           = false
  load_balancer_type = "application"
  ip_address_type    = "ipv4"
  security_groups    = [var.alb_security_group]
  subnets            = [var.subnet_ids[0], var.subnet_ids[1]]

  tags = {
    Name = join("-", ["WorkshopLoadBalancer", var.suffix])
  }
}

resource "aws_lb_listener" "workshop_listener" {
  load_balancer_arn = aws_lb.workshop_load_balancer.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.workshop_target_group.arn
  }

  tags = {
    Name = join("-", ["WorkshopListener", var.suffix])
  }
}

# EC2 Instance

resource "aws_instance" "workshop_web_server" {
  ami                  = data.aws_ssm_parameter.ami_id.value
  instance_type        = "t3.micro"
  iam_instance_profile = aws_iam_instance_profile.workshop_web_server_instance_profile.name
  key_name             = aws_key_pair.generated_key.key_name
  security_groups      = var.webserver_security_groups
  subnet_id            = var.subnet_ids[2]
  depends_on = [
    aws_iam_role.workshop_web_server_instance_role,
    aws_iam_instance_profile.workshop_web_server_instance_profile,
    aws_key_pair.generated_key,
    aws_lb_target_group.workshop_target_group,
    var.nat_gateway_id,
    var.ec2_instance_connect_id
  ]

  # user_data = base64encode(data.template_file.user_data.rendered)
  user_data = data.template_file.user_data.rendered

  metadata_options {
    http_tokens = "required"
  }

  tags = {
    Name = join("-", ["WorkshopWebserver", var.suffix])
  }
}

data "template_file" "user_data" {
  template = file("${path.module}/resources/user-data.sh")

  vars = {
    GITHUB_SOURCE_URL       = var.workshop_zip_file_location
    WORKSHOP_S3_BUCKET_NAME = var.s3_bucket_name
    TARGET_GROUP_ARN        = aws_lb_target_group.workshop_target_group.arn
  }
}
