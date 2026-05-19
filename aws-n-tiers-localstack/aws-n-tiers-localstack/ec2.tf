resource "aws_launch_template" "web" {
  name_prefix   = "${var.project_name}-web-"
  image_id      = "ami-12345678"
  instance_type = "t3.micro"

  vpc_security_group_ids = [
    aws_security_group.web.id
  ]

  user_data = base64encode(<<EOF
#!/bin/bash
echo "Web Server - ${var.project_name}" > /var/www/html/index.html
EOF
  )

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "${var.project_name}-web-server"
      Tier = "web"
    }
  }
}

resource "aws_autoscaling_group" "web" {
  name                = "${var.project_name}-asg"
  min_size            = 2
  max_size            = 4
  desired_capacity    = 3
  vpc_zone_identifier = aws_subnet.web[*].id

  # target_group_arns = [
  #   aws_lb_target_group.web.arn
  # ]

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-web-asg"
    propagate_at_launch = true
  }

  # depends_on = [
  #   aws_lb_listener.http
  # ]
}