terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 6.9.0"
    }
  }
}

variable "prod-vpc-euwest1-id" {
  description = "ID of prod VPC in eu-west-1"
}

resource "aws_security_group" "prod-external-alb-sg-euwest1" {
  description = "Security Group for prod external ALB in eu-west-1"
  vpc_id = var.prod-vpc-euwest1-id

  tags = {
    Name = "prod-external-alb-sg-euwest1"
  }
}

variable "CIDR-prod-route-igw-euwest1" {
  description = "CIDR used for prod route igw in eu-west-1"
}

variable "port-ingress-http-prod-frontend-public-a1-euwest1" {
  description = "Port used for ingress sg rule for HTTP for prod frontend public in eu-west-1"
}

resource "aws_vpc_security_group_ingress_rule" "prod-external-alb-ingress-euwest1" {
  cidr_ipv4         = var.CIDR-prod-route-igw-euwest1
  from_port         = var.port-ingress-http-prod-frontend-public-a1-euwest1
  ip_protocol       = "tcp"
  security_group_id = aws_security_group.prod-external-alb-sg-euwest1.id
  to_port           = var.port-ingress-http-prod-frontend-public-a1-euwest1
}

resource "aws_vpc_security_group_egress_rule" "prod-external-alb-egress-euwest1" {
  cidr_ipv4         = var.CIDR-prod-route-igw-euwest1
  ip_protocol       = "-1"
  security_group_id = aws_security_group.prod-external-alb-sg-euwest1.id
}

resource "aws_lb_target_group" "prod-external-alb-tg-euwest1" {
  name        = "prod-external-alb-tg-euwest1"
  port        = var.port-ingress-http-prod-frontend-public-a1-euwest1
  protocol    = "HTTP"
  vpc_id      = var.prod-vpc-euwest1-id

  health_check {
    protocol = "HTTP"
    timeout = 29  # XXX: we need to be relaxed here as there may be delay due to docker start-up
  }

  tags = {
    Name = "prod-external-alb-tg-euwest1"
  }
}

variable "prod-frontend-public-a1-ec2-instance-euwest1-id" {
  description = "ID of EC2 instance in prod frontend public a1 in eu-west-1"
}

resource "aws_lb_target_group_attachment" "prod-external-alb-tg-attachment-a1-euwest1" {
  target_group_arn = aws_lb_target_group.prod-external-alb-tg-euwest1.arn
  target_id        = var.prod-frontend-public-a1-ec2-instance-euwest1-id
  port             = var.port-ingress-http-prod-frontend-public-a1-euwest1
  depends_on       = [aws_lb_target_group.prod-external-alb-tg-euwest1]
}

variable "prod-frontend-public-b1-ec2-instance-euwest1-id" {
  description = "ID of EC2 instance in prod frontend public b1 in eu-west-1"
}

resource "aws_lb_target_group_attachment" "prod-frontend-public-alb-tg-attachment-b1-euwest1" {
  target_group_arn = aws_lb_target_group.prod-external-alb-tg-euwest1.arn
  target_id        = var.prod-frontend-public-b1-ec2-instance-euwest1-id
  port             = var.port-ingress-http-prod-frontend-public-a1-euwest1
  depends_on       = [aws_lb_target_group.prod-external-alb-tg-euwest1]
}

resource "aws_lb_listener" "prod-frontend-alb-listener-http-euwest1" {
  load_balancer_arn = aws_lb.prod-external-alb-euwest1.arn
  port              = var.port-ingress-http-prod-frontend-public-a1-euwest1
  protocol          = "HTTP"
  depends_on = [aws_lb_target_group.prod-external-alb-tg-euwest1]

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.prod-external-alb-tg-euwest1.arn
  }
}

variable "prod-frontend-public-subnet-a1-euwest1-id" {
  description = "ID of public subnet for frontend prod a1 in eu-west-1"
}

variable "prod-frontend-public-subnet-b1-euwest1-id" {
  description = "ID of public subnet for frontend prod b1 in eu-west-1"
}

variable "prod-frontend-public-a1-ec2-instance-euwest1" {
  description = "EC2 instance of prod frontend public a1 in eu-west-1"
}

variable "prod-frontend-public-b1-ec2-instance-euwest1" {
  description = "EC2 instance of prod frontend public b1 in eu-west-1"
}

output "alb_fqdn" {
  value = aws_lb.prod-external-alb-euwest1.dns_name
}

resource "aws_lb" "prod-external-alb-euwest1" {
  name = "prod-external-alb-euwest1"
  load_balancer_type = "application"
  security_groups = [aws_security_group.prod-external-alb-sg-euwest1.id]
  subnets = [var.prod-frontend-public-subnet-a1-euwest1-id, var.prod-frontend-public-subnet-b1-euwest1-id]

  depends_on = [
    var.prod-frontend-public-a1-ec2-instance-euwest1,
    var.prod-frontend-public-b1-ec2-instance-euwest1,
    aws_lb_target_group.prod-external-alb-tg-euwest1
  ]

  tags = {
    Name = "prod-frontend-public-alb-euwest1"
  }
}