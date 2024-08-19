output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "subnet_ids" {
  value = [
    aws_subnet.public_subnet_1.id,
    aws_subnet.public_subnet_2.id,
    aws_subnet.private_subnet_1.id,
    aws_subnet.private_subnet_2.id
  ]
}

output "external_http_sg" {
  value = aws_security_group.external_http_sg.id
}

output "ssh_from_instance_connect_sg" {
  value = aws_security_group.ssh_from_instance_connect_sg.id
}

output "internal_vpc_http_sg" {
  value = aws_security_group.internal_vpc_http_sg.id
}

output "workshop_nat_gateway_id" {
  value = aws_nat_gateway.workshop_nat_gateway.id
}

output "ec2_instance_connect_id" {
  value = aws_ec2_instance_connect_endpoint.ec2_instance_connect.id
}
