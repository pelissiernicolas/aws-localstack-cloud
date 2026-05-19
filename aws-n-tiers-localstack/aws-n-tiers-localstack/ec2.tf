resource "aws_key_pair" "localstack" {
  key_name   = "${var.project_name}-key"
  public_key = file("${path.module}/localstack.pub")
}

variable "web_ami_id" {
  description = "AMI ID compatible LocalStack Docker VM manager (Ubuntu 22.04 par défaut)"
  type        = string
  default     = "ami-df5de72bdb3b"
}

resource "aws_instance" "web" {
  ami                         = var.web_ami_id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public[0].id
  key_name                    = aws_key_pair.localstack.key_name
  vpc_security_group_ids      = [aws_security_group.web.id]
  associate_public_ip_address = true

  user_data = base64encode(<<EOF
#!/bin/bash
echo "Web Server - ${var.project_name}" > /var/www/html/index.html
EOF
  )

  tags = {
    Name = "${var.project_name}-web-1"
    Tier = "web"
  }
}
