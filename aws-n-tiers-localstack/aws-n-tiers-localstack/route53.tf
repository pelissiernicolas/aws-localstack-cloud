resource "aws_route53_zone" "main" {
  name = "lab-factory.com"

  tags = {
    Name = "${var.project_name}-zone"
  }
}

# resource "aws_route53_record" "app" {
#   zone_id = aws_route53_zone.main.zone_id
#   name    = "www.lab-factory.com"
#   type    = "A"

#   alias {
#     name                   = aws_lb.web.dns_name
# #    zone_id                = aws_lb.web.zone_id
#     evaluate_target_health = false
#   }
# }