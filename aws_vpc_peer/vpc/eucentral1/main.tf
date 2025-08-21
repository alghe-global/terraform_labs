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

variable "CIDR-prod-private-backend-vpc-eucentral1" {
  description = "CIDR for VPC of prod private backend in eu-central-1"
}

resource "aws_vpc" "prod-private-backend-vpc-eucentral1" {
  cidr_block = var.CIDR-prod-private-backend-vpc-eucentral1

  tags = {
    Name = "prod-private-backend-vpc-eucentral1"
  }
}

output "prod-private-frontend-peer-vpc-id-eucentral1" {
  value = aws_vpc.prod-private-backend-vpc-eucentral1.id
}

variable "CIDR-prod-private-backend-subnet-eucentral1" {
  description = "CIDR for subnet of prod private backend in eu-central-1"
}

resource "aws_subnet" "prod-private-backend-subnet-eucentral1" {
  vpc_id = aws_vpc.prod-private-backend-vpc-eucentral1.id
  cidr_block = var.CIDR-prod-private-backend-subnet-eucentral1
  availability_zone = "eu-central-1a"

  tags = {
    Name = "prod-private-backend-subnet-eucentral1"
  }
}

variable "CIDR-prod-public-backend-subnet-eucentral1" {
  description = "CIDR for subnet of prod public backend in eu-central-1 (used for NAT GW)"
}

resource "aws_subnet" "prod-public-backend-subnet-eucentral1" {
  vpc_id = aws_vpc.prod-private-backend-vpc-eucentral1.id
  cidr_block = var.CIDR-prod-public-backend-subnet-eucentral1

  tags = {
    Name = "prod-public-backend-subnet-eucentral1"
  }
}

resource "aws_eip" "prod-public-backend-ngw-eip-eucentral1" {
  domain = "vpc"
  depends_on = [aws_internet_gateway.prod-public-backend-eucentral1-igw]

  tags = {
    Name = "prod-public-backend-ngw-eip-eucentral1"
  }
}

variable "CIDR-prod-public-backend-route-ngw-eucentral1" {
  description = "CIDR for route rule of prod public backend NAT Gateway in eu-central-1"
}

resource "aws_nat_gateway" "prod-public-backend-ngw-eucentral1" {
  subnet_id = aws_subnet.prod-public-backend-subnet-eucentral1.id
  allocation_id = aws_eip.prod-public-backend-ngw-eip-eucentral1.id
  depends_on = [aws_internet_gateway.prod-public-backend-eucentral1-igw]

  tags = {
    Name = "prod-public-backend-ngw-eucentral1"
  }
}

resource "aws_route_table" "prod-private-backend-rt-eucentral1" {
  vpc_id = aws_vpc.prod-private-backend-vpc-eucentral1.id

  tags = {
    Name = "prod-private-backend-rt-eucentral1"
  }
}

output "prod-private-backend-rt-id-eucentral1" {
  value = aws_route_table.prod-private-backend-rt-eucentral1.id
}

resource "aws_route" "prod-private-backend-rt-eucentral1-route-ngw" {
  route_table_id = aws_route_table.prod-private-backend-rt-eucentral1.id

  destination_cidr_block = var.CIDR-prod-public-backend-route-ngw-eucentral1
  nat_gateway_id = aws_nat_gateway.prod-public-backend-ngw-eucentral1.id
}

resource "aws_route_table_association" "prod-private-backend-rt-eucentral1-route-association" {
  route_table_id = aws_route_table.prod-private-backend-rt-eucentral1.id
  subnet_id = aws_subnet.prod-private-backend-subnet-eucentral1.id
}

resource "aws_internet_gateway" "prod-public-backend-eucentral1-igw" {
  vpc_id = aws_vpc.prod-private-backend-vpc-eucentral1.id

  tags = {
    Name = "prod-public-backend-eucentral1-igw"
  }
}

resource "aws_route_table" "prod-public-backend-rt-eucentral1" {
  vpc_id = aws_vpc.prod-private-backend-vpc-eucentral1.id

  tags = {
    Name = "prod-public-backend-rt-eucentral1"
  }
}

resource "aws_route" "prod-public-backend-rt-eucentral1-route-igw" {
  route_table_id = aws_route_table.prod-public-backend-rt-eucentral1.id

  destination_cidr_block = var.CIDR-prod-public-backend-route-ngw-eucentral1
  gateway_id = aws_internet_gateway.prod-public-backend-eucentral1-igw.id
}

resource "aws_route_table_association" "prod-public-backend-rt-eucentral1-route-association" {
  route_table_id = aws_route_table.prod-public-backend-rt-eucentral1.id
  subnet_id = aws_subnet.prod-public-backend-subnet-eucentral1.id
}

resource "aws_security_group" "prod-private-backend-sg-eucentral1" {
  name = "prod-private-backend-sg-eucetral1"
  description = "Security Group allowing Mongo and SSH for prod private backend EC2 instance in eu-central-1"
  vpc_id = aws_vpc.prod-private-backend-vpc-eucentral1.id

  tags = {
    Name = "prod-private-backend-sg-eucentral1"
  }
}

variable "prod-public-backend-mongo-port-sg-rule-eucentral1" {
  description = "Mongo port to receive traffic on for prod private backend EC2 instance security group rule"
}

resource "aws_vpc_security_group_ingress_rule" "prod-private-backend-mongo-sg-ingress-rule-eucentral1" {
  cidr_ipv4         = "${var.prod-public-frontend-ec2-instance-euwest1-private-ip}/32"
  from_port         = var.prod-public-backend-mongo-port-sg-rule-eucentral1
  ip_protocol       = "tcp"
  security_group_id = aws_security_group.prod-private-backend-sg-eucentral1.id
  to_port           = var.prod-public-backend-mongo-port-sg-rule-eucentral1
}

variable "prod-private-backend-ssh-port-sg-rule-eucentral1" {
  description = "SSH port to receive traffic on for prod private backend EC2 instance security group rule"
}

resource "aws_vpc_security_group_ingress_rule" "prod-private-backend-ssh-sg-ingress-rule-eucentral1" {
  cidr_ipv4         = var.CIDR-prod-public-backend-route-ngw-eucentral1
  from_port         = var.prod-private-backend-ssh-port-sg-rule-eucentral1
  ip_protocol       = "tcp"
  security_group_id = aws_security_group.prod-private-backend-sg-eucentral1.id
  to_port           = var.prod-private-backend-ssh-port-sg-rule-eucentral1
}

resource "aws_vpc_security_group_egress_rule" "prod-private-backend-sg-egress-rule-eucentral1" {
  cidr_ipv4         = var.CIDR-prod-public-backend-route-ngw-eucentral1
  from_port         = 0
  ip_protocol       = "-1"
  security_group_id = aws_security_group.prod-private-backend-sg-eucentral1.id
  to_port           = 0
}

variable "prod-public-frontend-ec2-instance-euwest1-private-ip" {
  description = "Private IP of prod public frontend EC2 instance in eu-west-1"
}

variable "prod-private-backend-ec2-instance-eucentral1-private-ip" {
  description = "Private IP of prod private backend EC2 instance in eu-central-1"
}

resource "aws_instance" "prod-private-backend-ec2-instance-eucentral1" {
  ami = "ami-02003f9f0fde924ea"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.prod-private-backend-subnet-eucentral1.id
  private_ip = var.prod-private-backend-ec2-instance-eucentral1-private-ip
  security_groups = [aws_security_group.prod-private-backend-sg-eucentral1.id]
  key_name = "lab"
  depends_on = [aws_nat_gateway.prod-public-backend-ngw-eucentral1]

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

# Run MongoDB container
docker run -d --name mongo \
    -e MONGO_INITDB_ROOT_USERNAME=${var.MONGODB_USER} \
    -e MONGO_INITDB_ROOT_PASSWORD=${var.MONGODB_PASSWORD} \
    -p 27017:27017 \
    mongo
EOF

  tags = {
    Name = "prod-private-backend-ec2-instance-eucentral1"
  }
}