data "aws_vpc" "default_vpc" {
  default = true
}

data "aws_subnet_ids" "default_subnet" {
  vpc_id = data.aws_vpc.default_vpc.id
}

resource "aws_instance" "http_instance" {
  ami                    = var.ami
  instance_type          = "t2.micro"
  availability_zone      = var.ZONE
  vpc_security_group_ids = [aws_security_group.http_server_security_group.id]
  key_name               = var.key_pair_name
  tags = {
    Name = var.instance_name
  }
  iam_instance_profile = var.instance_profile
  user_data            = <<-EOF
        #!/bin/bash
        sudo apt update -y
        sudo apt install git -y
        sudo apt install awscli -y
        sudo apt install python3-pip -y
        sudo apt install uvicorn -y
        cd /home/ubuntu
        git clone https://github.com/ardhendusgit/OnetoN-Assignment.git
        pip3 install -r /home/ubuntu/OnetoN-Assignment/requirements.txt
        cd /home/ubuntu/OnetoN-Assignment/http-server
        uvicorn main:app --host 0.0.0.0 --port 8000
    EOF
}

resource "aws_security_group" "http_server_security_group" {
  name = "http-server-sg"
}

resource "aws_security_group_rule" "allow_http_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.http_server_security_group.id

  from_port                = 8000
  to_port                  = 8000
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
}

resource "aws_security_group_rule" "allow_all_outbound" {
  type              = "egress"
  security_group_id = aws_security_group.http_server_security_group.id
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}


resource "aws_security_group" "alb" {
  name = "alb-security-group"
}

resource "aws_lb" "load_balancer" {
  name               = "http-server-lb"
  load_balancer_type = "application"
  subnets            = data.aws_subnet_ids.default_subnet.ids
  security_groups    = [aws_security_group.alb.id]

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
    port                = 8000
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

resource "aws_lb_listener_rule" "listener_rule_http" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.http_server_target_group.arn
  }
}