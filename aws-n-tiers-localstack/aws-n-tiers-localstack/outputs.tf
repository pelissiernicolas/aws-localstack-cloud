output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnets" {
  value = aws_subnet.public[*].id
}

output "web_subnets" {
  value = aws_subnet.web[*].id
}

output "db_subnets" {
  value = aws_subnet.db[*].id
}

# output "load_balancer_dns" {
#   value = aws_lb.web.dns_name
# }

output "rds_endpoint" {
  value = aws_db_instance.main.endpoint
}

# output "route53_record" {
#   value = aws_route53_record.app.fqdn
# }