resource "aws_instance" "http_instance" {
  ami                    = var.ami
  instance_type          = "t2.micro"
  availability_zone      = var.ZONE
  vpc_security_group_ids = [var.security_group_id]
  key_name               = var.key_pair_name
  tags = {
    Name = var.instance_name
  }
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "s3_role_instance_profile"
  role = var.role
}

resource "aws_security_group" "http_server_security_group" {
  name = "http-server-sg"
}

resource "aws_security_group_rule" "allow_app_tcp_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.http_server_security_group.id

  from_port   = 8000
  to_port     = 8000
  protocol    = "tcp"
  source_security_group_id = aws_security_group.alb.id
}

resource "aws_security_group" "alb" {
  name = "alb-security-group"
}

resource "aws_security_group_rule" "allow_alb_http_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.alb.id

  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

}

resource "aws_security_group_rule" "allow_alb_http_outbound" {
  type              = "egress"
  security_group_id = aws_security_group.alb.id

  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.load_balancer.arn

  port = 80

  protocol = "HTTP"

  # By default, we will return a simple 404 page
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code  = 404
    }
  }
}

# resource "aws_lb_listener" "https" {
#   load_balancer_arn = aws_lb.load_balancer.arn

#   port = 443

#   protocol = "HTTPS"

#   # By default, return a simple 404 page
#   default_action {
#     type = "fixed-response"

#     fixed_response {
#       content_type = "text/plain"
#       message_body = "404: page not found"
#       status_code  = 404
#     }
#   }
# }

resource "aws_lb_target_group" "http_server_target_group" {
  name     = "http-server-target-group"
  port     = 8000
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default_vpc.id

  health_check {
    path                = "/list-bucket-content"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group_attachment" "http_tg_attachment" {
  target_group_arn = aws_lb_target_group.http_server_target_group.arn
  target_id        = aws_instance.http_instance.id
  port             = 8000
}