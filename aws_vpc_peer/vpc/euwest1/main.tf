variable "MONGODB_USER" {
  description = "MongoDB user to use for setting up backend as well as frontend"
}

variable "MONGODB_PASSWORD" {
  description = "MongoDB password to use for setting up backend as well as frontend"
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 6.9.0"
    }
  }
}

variable "CIDR-prod-public-frontend-vpc-euwest1" {
  description = "CIDR for VPC of prod public frontend in eu-west-1"
}

resource "aws_vpc" "prod-public-frontend-vpc-euwest1" {
  cidr_block = var.CIDR-prod-public-frontend-vpc-euwest1

  tags = {
    Name = "prod-public-frontend-vpc-euwest1"
  }
}

output "prod-public-frontend-vpc-id-euwest1" {
  value = aws_vpc.prod-public-frontend-vpc-euwest1.id
}

resource "aws_internet_gateway" "prod-public-frontend-igw-euwest1" {
  vpc_id = aws_vpc.prod-public-frontend-vpc-euwest1.id

  tags = {
    Name = "prod-public-frontend-igw-euwest1"
  }
}

variable "CIDR-prod-public-frontend-subnet-euwest1" {
  description = "CIDR for subnet of prod public frontend in eu-west-1"
}

resource "aws_subnet" "prod-public-frontend-subnet-euwest1" {
  vpc_id = aws_vpc.prod-public-frontend-vpc-euwest1.id
  cidr_block = var.CIDR-prod-public-frontend-subnet-euwest1
  availability_zone = "eu-west-1a"

  tags = {
    Name = "prod-public-frontend-subnet-euwest1"
  }
}

resource "aws_route_table" "prod-public-frontend-rt-euwest1" {
  vpc_id = aws_vpc.prod-public-frontend-vpc-euwest1.id

  tags = {
    Name = "prod-public-frontend-rt"
  }
}

output "prod-public-frontend-rt-id-euwest1" {
  value = aws_route_table.prod-public-frontend-rt-euwest1.id
}

variable "CIDR-prod-public-frontend-route-euwest1" {
  description = "TO CIDR to route traffic for to Internet Gateway in route table of prod public frontend eu-west-1"
}

resource "aws_route" "prod-public-frontend-route-euwest1" {
  route_table_id = aws_route_table.prod-public-frontend-rt-euwest1.id

  destination_cidr_block = var.CIDR-prod-public-frontend-route-euwest1
  gateway_id = aws_internet_gateway.prod-public-frontend-igw-euwest1.id
}

resource "aws_route_table_association" "prod-public-frontend-route-association-euwest1" {
  route_table_id = aws_route_table.prod-public-frontend-rt-euwest1.id
  subnet_id = aws_subnet.prod-public-frontend-subnet-euwest1.id
}

resource "aws_security_group" "prod-public-frontend-sg-euwest1" {
  name = "prod-public-frontend-sg-euwest1"
  description = "Security Group allowing HTTP and SSH for prod public frontend EC2 instance in eu-west-1"
  vpc_id = aws_vpc.prod-public-frontend-vpc-euwest1.id

  tags = {
    Name = "prod-public-frontend-sg-euwest1"
  }
}

variable "prod-public-frontend-http-port-sg-rule-euwest1" {
  default = "HTTP port to receive traffic on for prod public frontend EC2 instance security group rule"
}

resource "aws_vpc_security_group_ingress_rule" "prod-public-frontend-http-sg-ingress-rule-euwest1" {
  cidr_ipv4         = var.CIDR-prod-public-frontend-route-euwest1
  from_port         = var.prod-public-frontend-http-port-sg-rule-euwest1
  ip_protocol       = "tcp"
  security_group_id = aws_security_group.prod-public-frontend-sg-euwest1.id
  to_port           = var.prod-public-frontend-http-port-sg-rule-euwest1
}

variable "prod-public-frontend-ssh-port-sg-rule-euwest1" {
  description = "SSH port to receive traffic on for prod public frontend EC2 instance security group rule"
}

resource "aws_vpc_security_group_ingress_rule" "prod-public-frontend-ssh-sg-ingress-rule-euwest1" {
  cidr_ipv4         = var.CIDR-prod-public-frontend-route-euwest1
  from_port         = var.prod-public-frontend-ssh-port-sg-rule-euwest1
  ip_protocol       = "tcp"
  security_group_id = aws_security_group.prod-public-frontend-sg-euwest1.id
  to_port           = var.prod-public-frontend-ssh-port-sg-rule-euwest1
}

resource "aws_vpc_security_group_egress_rule" "prod-public-frontend-sg-egress-rule-euwest1" {
  cidr_ipv4         = var.CIDR-prod-public-frontend-route-euwest1
  from_port         = 0
  ip_protocol       = "-1"
  security_group_id = aws_security_group.prod-public-frontend-sg-euwest1.id
  to_port           = 0
}

variable "prod-public-frontend-ec2-instance-euwest1-private-ip" {
  description = "Private IP of prod public frontend EC2 instance in eu-west-1"
}

variable "prod-private-backend-ec2-instance-eucentral1-private-ip" {
  description = "Private IP of prod private backend EC2 instance in eu-central-1"
}

resource "aws_instance" "prod-public-frontend-ec2-instance-euwest1" {
  ami = "ami-01f23391a59163da9"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.prod-public-frontend-subnet-euwest1.id
  private_ip = var.prod-public-frontend-ec2-instance-euwest1-private-ip
  associate_public_ip_address = true
  security_groups = [aws_security_group.prod-public-frontend-sg-euwest1.id]
  key_name = "lab"
  depends_on = [aws_internet_gateway.prod-public-frontend-igw-euwest1]

  user_data = <<-EOF
#!/bin/bash
sudo apt update

# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${"$"}{UBUNTU_CODENAME:-${"$"}VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

# Install Docker
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

docker run -d --name aws_vpc_api \
    -e MONGODB_USER=${var.MONGODB_USER} \
    -e MONGODB_PASSWORD=${var.MONGODB_PASSWORD} \
    -e MONGODB_HOST=${var.prod-private-backend-ec2-instance-eucentral1-private-ip} \
    -p 80:80 \
    algheglobal/aws_vpc:latest
EOF

  tags = {
    Name = "prod-public-frontend-ec2-instance-euwest1"
  }
}