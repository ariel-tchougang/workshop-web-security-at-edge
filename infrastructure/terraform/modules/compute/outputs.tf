output "workshop_webserver_id" {
  description = "Workshop Webserver instance ID"
  value       = aws_instance.workshop_web_server.id
}

output "workshop_load_balancer_dns_name" {
  description = "The DNS name of the Workshop Load Balancer"
  value       = aws_lb.workshop_load_balancer.dns_name
}

# output "rendered_user_data" {
#   value = data.template_file.user_data.rendered
# }
