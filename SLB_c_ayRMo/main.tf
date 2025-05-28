variable "AWS_ACCESS_KEY" {
  description = "AWS Access Key to use with provider. Set through environment variable TF_VAR_AWS_ACCESS_KEY"
}

variable "AWS_SECRET_KEY" {
  description = "AWS Secret Key to use with provider. Set through environment variable TF_VAR_AWS_SECRET_KEY"
}

provider "aws" {
  region = "us-east-1"
  access_key = var.AWS_ACCESS_KEY
  secret_key = var.AWS_SECRET_KEY
}

#resource "aws_subnet" "subnet-1" {
#  vpc_id     = aws_vpc.first-vpc.id
#  cidr_block = "10.0.1.0/24"
#
#  tags = {
#    Name = "prod-subnet"
#  }
#}
#
#resource "aws_vpc" "first-vpc" {
#  cidr_block = "10.0.0.0/16"
#  tags = {
#    Name = "production"
#  }
#}

###########################
# -- Apache lab project --
###########################

#resource "aws_vpc" "prod-vpc" {
#  cidr_block = "10.0.0.0/16"
#  tags = {
#    Name = "production"
#  }
#}
#
#resource "aws_internet_gateway" "gw" {
#  vpc_id = aws_vpc.prod-vpc.id
#}
#
#resource "aws_route_table" "prod-route-table" {
#  vpc_id = aws_vpc.prod-vpc.id
#
#  route {
#    cidr_block = "0.0.0.0/0"
#    gateway_id = aws_internet_gateway.gw.id
#  }
#
#  route {
#    ipv6_cidr_block = "::/0"
#    gateway_id = aws_internet_gateway.gw.id
#  }
#
#  tags = {
#    Name = "prod"
#  }
#}
#
#resource "aws_subnet" "subnet-1" {
#  vpc_id = aws_vpc.prod-vpc.id
#  cidr_block = "10.0.1.0/24"
#  availability_zone = "us-east-1a"
#
#  tags = {
#    Name = "prod-subnet"
#  }
#}
#
#resource "aws_route_table_association" "a" {
#  subnet_id      = aws_subnet.subnet-1.id
#  route_table_id = aws_route_table.prod-route-table.id
#}
#
#resource "aws_security_group" "allow_web" {
#  name        = "allow_web_traffic"
#  description = "Allow Web inbound traffic"
#  vpc_id      = aws_vpc.prod-vpc.id
#
#  ingress {
#    description = "HTTPS"
#    from_port   = 443
#    to_port     = 443
#    protocol    = "tcp"
#    cidr_blocks = ["0.0.0.0/0"]
#  }
#
#  ingress {
#    description = "HTTP"
#    from_port   = 80
#    to_port     = 80
#    protocol    = "tcp"
#    cidr_blocks = ["0.0.0.0/0"]
#  }
#
#  ingress {
#    description = "SSH"
#    from_port   = 22
#    to_port     = 22
#    protocol    = "tcp"
#    cidr_blocks = ["0.0.0.0/0"]
#  }
#
#  egress {
#    from_port   = 0
#    to_port     = 0
#    protocol    = "-1"  # any protocol
#    cidr_blocks = ["0.0.0.0/0"]
#  }
#
#  tags = {
#    Name = "allow_web"
#  }
#}
#
#resource "aws_network_interface" "web-server-nic" {
#  subnet_id       = aws_subnet.subnet-1.id
#  private_ips     = ["10.0.1.50"]
#  security_groups = [aws_security_group.allow_web.id]
#}
#
#resource "aws_eip" "lb" {
#  domain = "vpc"
#  network_interface = aws_network_interface.web-server-nic.id
#  associate_with_private_ip = "10.0.1.50"
#  depends_on = [aws_internet_gateway.gw]  # create the EIP only after the gateway exists
#}
#
#output "server_public_ip" {
#  value = aws_eip.lb.public_ip
#}
#
#resource "aws_instance" "web-server-instance" {
#  ami           = "ami-084568db4383264d4"
#  instance_type = "t3.micro"
#  availability_zone = "us-east-1a"
#  key_name = "lab.key"
#
#  network_interface {
#    device_index         = 0
#    network_interface_id = aws_network_interface.web-server-nic.id
#  }
#
#  user_data = <<-EOF
#      #!/bin/bash
#      sudo apt update -y
#      sudo apt install apache2 -y
#      sudo systemctl start apache2
#      sudo bash -c "echo your very first web server > /var/www/html/index.html"
#      EOF
#
#  tags = {
#    Name = "prod-web-server"
#  }
#}
#
#output "instance_private_ip" {
#  value = aws_instance.web-server-instance.private_ip
#}
#
#output "instance_id" {
#  value = aws_instance.web-server-instance.id
#}


#####################
# -- Variables lab --
#####################

resource "aws_vpc" "prod-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "prod"
  }
}

variable "subnet_tags" {
  description = "Hash containing tags for subnets"
}

variable "subnet_prefix" {
  description = "CIDR block for the subnet"
  default = "10.0.2.0/24"
  type = string
}

resource "aws_subnet" "subnet-1" {
  vpc_id = aws_vpc.prod-vpc.id
  cidr_block = var.subnet_prefix
  availability_zone = "us-east-1a"

  tags = {
    Name = var.subnet_tags[0].subnet_name
  }
}

variable "subnet2_prefix" {
  description = "CIDR block for dev subnet"
}

resource "aws_subnet" "subnet-2" {
  vpc_id = aws_vpc.prod-vpc.id
  cidr_block = var.subnet2_prefix[0]
  availability_zone = "us-east-1a"

  tags = {
    Name = var.subnet_tags[1].subnet2_name
  }
}