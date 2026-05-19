output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnets" {
  value = aws_subnet.public[*].id
}

output "web_subnets" {
  value = aws_subnet.web[*].id
}

# output "load_balancer_dns" {
#   value = aws_lb.web.dns_name
# }

output "dynamodb_table_name" {
  value = aws_dynamodb_table.main.name
}

output "dynamodb_table_arn" {
  value = aws_dynamodb_table.main.arn
}

output "web_instance_id" {
  value = aws_instance.web.id
}

output "web_public_ip" {
  value = aws_instance.web.public_ip
}

output "ssh_command" {
  value = "ssh -o StrictHostKeyChecking=no -i ${path.module}/localstack ubuntu@${aws_instance.web.public_ip}"
}

output "db_secret_arn" {
  description = "ARN du secret AWS Secrets Manager contenant les credentials de la DB"
  value       = aws_secretsmanager_secret.db_credentials.arn
}

output "db_secret_name" {
  description = "Nom du secret AWS Secrets Manager - à utiliser avec GetSecretValue"
  value       = aws_secretsmanager_secret.db_credentials.name
}

# output "route53_record" {
#   value = aws_route53_record.app.fqdn
# }