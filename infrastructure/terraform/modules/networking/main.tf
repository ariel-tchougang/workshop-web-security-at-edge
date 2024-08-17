# VPC and subnets

resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = join("-", ["WorkshopVPC", var.suffix])
  }
}

resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, 0)
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[0]

  tags = {
    Name = join("-", ["WorkshopPublicSubnet1", var.suffix])
  }
}

resource "aws_subnet" "private_subnet_1" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, 1)
  map_public_ip_on_launch = false
  availability_zone       = data.aws_availability_zones.available.names[0]

  tags = {
    Name = join("-", ["WorkshopPrivateSubnet1", var.suffix])
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, 2)
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[1]

  tags = {
    Name = join("-", ["WorkshopPublicSubnet2", var.suffix])
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, 3)
  map_public_ip_on_launch = false
  availability_zone       = data.aws_availability_zones.available.names[1]

  tags = {
    Name = join("-", ["WorkshopPrivateSubnet2", var.suffix])
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

# Internet Gateway

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = join("-", ["WorkshopIGW", var.suffix])
  }
}

# NAT Gateway

resource "aws_eip" "nat" {
  domain = "vpc"
}

resource "aws_nat_gateway" "workshop_nat_gateway" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_subnet_1.id

  tags = {
    Name = join("-", ["WorkshopNATGW", var.suffix])
  }
}

# Route tables

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = join("-", ["WorkshopPublicRTB", var.suffix])
  }
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = join("-", ["WorkshopPrivateRTB", var.suffix])
  }
}

# Internet routes

resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = local.all_ipv4_cidr
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route" "private_route" {
  route_table_id         = aws_route_table.private_route_table.id
  destination_cidr_block = local.all_ipv4_cidr
  nat_gateway_id         = aws_nat_gateway.workshop_nat_gateway.id
}

# Subnet associations

resource "aws_route_table_association" "public_subnet_route_table_association_1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_subnet_route_table_association_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "private_subnet_route_table_association_1" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "private_subnet_route_table_association_2" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_route_table.id
}

# Security Groups

resource "aws_security_group" "ec2_instance_connect_sg" {
  name        = "EC2-instance-connect-SG"
  description = "Allow SSH outbound to VPC CIDR"
  vpc_id      = aws_vpc.vpc.id

  egress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "Allow SSH outbound to VPC CIDR"
  }

  tags = {
    Name = join("-", ["EC2-instance-connect-SG", var.suffix])
  }
}

resource "aws_security_group" "ssh_from_instance_connect_sg" {
  name        = "SSH-from-instance-connect-SG"
  description = "Allow SSH from EC2 Instance Connect"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_instance_connect_sg.id]
    description     = "Allow SSH from EC2 Instance Connect"
  }

  tags = {
    Name = join("-", ["SSH-from-instance-connect-SG", var.suffix])
  }
}

resource "aws_security_group" "internal_vpc_http_sg" {
  name        = "Internal-vpc-http-SG"
  description = "Allow http and https traffic from within the VPC"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "Allow http traffic from within the VPC"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "Allow https traffic from within the VPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # -1 means all protocols
    cidr_blocks = [local.all_ipv4_cidr]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = join("-", ["Internal-vpc-http-SG", var.suffix])
  }
}

resource "aws_security_group" "external_http_sg" {
  name        = "External-http-SG"
  description = "Allow http and https traffic from Internet"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [local.all_ipv4_cidr]
    description = "Allow http traffic from Internet"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [local.all_ipv4_cidr]
    description = "Allow https traffic from Internet"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # -1 means all protocols
    cidr_blocks = [local.all_ipv4_cidr]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = join("-", ["External-http-SG", var.suffix])
  }
}

# VPC Endpoints

resource "aws_vpc_endpoint" "s3_gateway" {
  vpc_id       = aws_vpc.vpc.id
  service_name = "com.amazonaws.${var.region}.s3"
  route_table_ids = [
    aws_route_table.public_route_table.id,
    aws_route_table.private_route_table.id
  ]
  vpc_endpoint_type = "Gateway"

  tags = {
    Name = join("-", ["WorkshopS3GatewayEndpoint", var.suffix])
  }
}

resource "aws_ec2_instance_connect_endpoint" "ec2_instance_connect" {
  subnet_id = aws_subnet.private_subnet_2.id
  security_group_ids = [aws_security_group.ec2_instance_connect_sg.id]

  tags = {
    Name = join("-", ["WorkshopEc2InstanceConnectEndpoint", var.suffix])
  }
}

