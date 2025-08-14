terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "= 6.8.0"
    }
  }
}

variable "cidr-prod-vpc-euwest1" {
  description = "CIDR block for prod VPC in eu-west-1"
}

resource "aws_vpc" "prod-vpc-euwest1" {
  cidr_block = var.cidr-prod-vpc-euwest1

  tags = {
    Name = "prod-vpc-euwest1"
  }
}

resource "aws_internet_gateway" "prod-igw-euwest1" {
  vpc_id = aws_vpc.prod-vpc-euwest1.id

  tags = {
    Name = "prod-igw-euwest1"
  }
}

variable "cidr-prod-public-subnet-euwest1" {
  description = "CIDR block for prod public subnet in eu-west-1"
}

variable "az-prod-public-subnet-euwest1" {
  description = "Which AZ in eu-west-1 to use for prod public subnet"
}

resource "aws_subnet" "prod-public-subnet-euwest1" {
  vpc_id = aws_vpc.prod-vpc-euwest1.id
  cidr_block = var.cidr-prod-public-subnet-euwest1
  availability_zone = var.az-prod-public-subnet-euwest1

  tags = {
    Name = "prod-public-subnet-euwest1"
  }
}

resource "aws_eip" "prod-public-nat-gw-eip-euwest1" {
  domain = "vpc"
  depends_on = [aws_internet_gateway.prod-igw-euwest1]

  tags = {
    Name = "prod-public-nat-gw-eip-euwest1"
  }
}

output "prod-public-nat-gw-eip-euwest1" {
  value = aws_eip.prod-public-nat-gw-eip-euwest1.address
}

resource "aws_nat_gateway" "prod-public-nat-gw-euwest1" {
  allocation_id = aws_eip.prod-public-nat-gw-eip-euwest1.id
  subnet_id = aws_subnet.prod-public-subnet-euwest1.id
  depends_on = [aws_internet_gateway.prod-igw-euwest1]

  tags = {
    Name = "prod-public-nat-gw-euwest1"
  }
}

variable "cidr-prod-private-subnet-euwest1" {
  description = "CIDR block for prod private subnet in eu-west-1"
}

variable "az-prod-private-subnet-euwest1" {
  description = "Which AZ in eu-west-1 to use for prod private subnet"
}

resource "aws_subnet" "prod-private-subnet-euwest1" {
  vpc_id = aws_vpc.prod-vpc-euwest1.id
  cidr_block = var.cidr-prod-private-subnet-euwest1
  availability_zone = var.az-prod-private-subnet-euwest1

  tags = {
    Name = "prod-private-subnet-euwest1"
  }
}

variable "cidr-all-route-table-prod-nat-gw-euwest1" {
  description = "All CIDR route for route table prod in eu-west-1"
}

resource "aws_route_table" "prod-route-table-igw-euwest1" {
  vpc_id = aws_vpc.prod-vpc-euwest1.id

  route {
    cidr_block = var.cidr-all-route-table-prod-nat-gw-euwest1
    gateway_id = aws_internet_gateway.prod-igw-euwest1.id
  }
}

resource "aws_route_table_association" "prod-route-table-igw-association-euwest1" {
  subnet_id = aws_subnet.prod-public-subnet-euwest1.id
  route_table_id = aws_route_table.prod-route-table-igw-euwest1.id
}

resource "aws_route_table" "prod-route-table-nat-gw-euwest1" {
  vpc_id = aws_vpc.prod-vpc-euwest1.id
  
  route {
    cidr_block = var.cidr-all-route-table-prod-nat-gw-euwest1
    gateway_id = aws_nat_gateway.prod-public-nat-gw-euwest1.id
  }
}

resource "aws_route_table_association" "prod-route-table-nat-gw-association-euwest1" {
  subnet_id = aws_subnet.prod-private-subnet-euwest1.id
  route_table_id = aws_route_table.prod-route-table-nat-gw-euwest1.id
}

resource "aws_security_group" "prod-public-ec2-instance-sg-euwest1" {
  name = "prod-public-ec2-instance-sg-euwest1"
  description = "Allow SSH and HTTP traffic for prod public EC2 instance in eu-west-1"
  vpc_id = aws_vpc.prod-vpc-euwest1.id

  tags = {
    Name = "prod-public-ec2-instance-sg-euwest1"
  }
}

variable "cidr-prod-public-ec2-instance-sg-rule-ingress-ssh-http-euwest1" {
  description = "CIDR block for Ingress rule allowing SSH to prod public ec2 instance in eu-west-1"
}

variable "port-prod-public-ec2-instance-sg-rule-ingress-ssh-euwest1" {
  description = "To port for Ingress rule allowing SSH to prod public ec2 instance in eu-west-1"
}

resource "aws_vpc_security_group_ingress_rule" "prod-public-ec2-instance-sg-rule-ingress-ssh-euwest1" {
  security_group_id = aws_security_group.prod-public-ec2-instance-sg-euwest1.id

  cidr_ipv4 = var.cidr-prod-public-ec2-instance-sg-rule-ingress-ssh-http-euwest1
  from_port = var.port-prod-public-ec2-instance-sg-rule-ingress-ssh-euwest1
  ip_protocol = "tcp"
  to_port = var.port-prod-public-ec2-instance-sg-rule-ingress-ssh-euwest1
}

variable "port-prod-public-ec2-instance-sg-rule-ingress-http-euwest1" {
  description = "To port for Ingress rule allowing HTTP to prod public ec2 instance in eu-west-1"
}

resource "aws_vpc_security_group_ingress_rule" "prod-public-ec2-instance-sg-rule-ingress-http-euwest1" {
  security_group_id = aws_security_group.prod-public-ec2-instance-sg-euwest1.id

  cidr_ipv4 = var.cidr-prod-public-ec2-instance-sg-rule-ingress-ssh-http-euwest1
  from_port = var.port-prod-public-ec2-instance-sg-rule-ingress-http-euwest1
  ip_protocol = "tcp"
  to_port = var.port-prod-public-ec2-instance-sg-rule-ingress-http-euwest1
}

variable "cidr-prod-public-ec2-instance-sg-rule-egress-ssh-euwest1" {
  description = "CIDR block for Egress rule allowing all traffic from prod public ec2 instance in eu-west-1"
}

resource "aws_vpc_security_group_egress_rule" "prod-public-ec2-instance-sg-rule-egress-euwest1" {
  security_group_id = aws_security_group.prod-public-ec2-instance-sg-euwest1.id
  cidr_ipv4 = var.cidr-prod-public-ec2-instance-sg-rule-egress-ssh-euwest1
  ip_protocol = "-1"
}

variable "MONGODB_USER" {
  description = "Username for MongoDB to init with and the API to authenticate with"
}

variable "MONGODB_PASSWORD" {
  description = "Password for MongoDB To init with and the API to authenticate with"
}

resource "aws_instance" "prod-public-ec2-instance-euwest1" {
  ami = "ami-01f23391a59163da9"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.prod-public-subnet-euwest1.id
  associate_public_ip_address = true
  security_groups = [aws_security_group.prod-public-ec2-instance-sg-euwest1.id]
  key_name = "lab"
  depends_on = [aws_internet_gateway.prod-igw-euwest1]

  user_data = <<-EOF
#!/bin/bash
sudo apt update

# Add Docker's official GPG key:
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  ${"$"}(. /etc/os-release && echo "${"$"}{UBUNTU_CODENAME:-${"$"}VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

# Install Docker
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

docker run -d --name aws_vpc_api \
    -e MONGODB_USER=${var.MONGODB_USER} \
    -e MONGODB_PASSWORD=${var.MONGODB_PASSWORD} \
    -e MONGODB_HOST=${var.prod-private-ec2-instance-euwest1-private-ip} \
    -p 80:80 \
    algheglobal/aws_vpc:latest
EOF

  tags = {
    Name = "prod-public-ec2-instance-euwest1"
  }
}

output "prod-public-ec2-instance-eip-euwest1" {
  value = aws_instance.prod-public-ec2-instance-euwest1.public_ip
}

resource "aws_security_group" "prod-private-ec2-instance-sg-euwest1" {
  name = "prod-private-ec2-instance-sg-euwest1"
  description = "Allow all traffic to SSH and MongoDB from prod public subnet in eu-west-1"
  vpc_id = aws_vpc.prod-vpc-euwest1.id

  tags = {
    Name = "prod-private-ec2-instance-sg-euwest1"
  }
}

resource "aws_vpc_security_group_ingress_rule" "prod-private-ec2-instance-sg-rule-ingress-ssh-euwest1" {
  security_group_id = aws_security_group.prod-private-ec2-instance-sg-euwest1.id

  cidr_ipv4 = aws_subnet.prod-public-subnet-euwest1.cidr_block
  from_port = var.port-prod-public-ec2-instance-sg-rule-ingress-ssh-euwest1
  ip_protocol = "tcp"
  to_port = var.port-prod-public-ec2-instance-sg-rule-ingress-ssh-euwest1
}

resource "aws_vpc_security_group_egress_rule" "prod-private-ec2-instance-sg-rule-egress-euwest1" {
  security_group_id = aws_security_group.prod-private-ec2-instance-sg-euwest1.id
  cidr_ipv4 = var.cidr-prod-public-ec2-instance-sg-rule-egress-ssh-euwest1
  ip_protocol = "-1"
}

variable "port-prod-private-ec2-instance-sg-rule-ingress-mongo-euwest1" {
  description = "To port for Security Group ingress rule for EC2 instance in private prod eu-west-1 subnet"
}

resource "aws_vpc_security_group_ingress_rule" "prod-private-ec2-instance-sg-rule-ingress-mongo-euwest1" {
  security_group_id = aws_security_group.prod-private-ec2-instance-sg-euwest1.id

  cidr_ipv4 = aws_subnet.prod-public-subnet-euwest1.cidr_block
  from_port = var.port-prod-private-ec2-instance-sg-rule-ingress-mongo-euwest1
  ip_protocol = "tcp"
  to_port = var.port-prod-private-ec2-instance-sg-rule-ingress-mongo-euwest1
}

variable "prod-private-ec2-instance-euwest1-private-ip" {
  description = "Private IP in private subnet of VPC to use for EC2 instance in eu-west-1"
}

resource "aws_instance" "prod-private-ec2-instance-euwest1" {
  ami = "ami-01f23391a59163da9"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.prod-private-subnet-euwest1.id
  security_groups = [aws_security_group.prod-private-ec2-instance-sg-euwest1.id]
  private_ip = var.prod-private-ec2-instance-euwest1-private-ip
  key_name = "lab"
  depends_on = [aws_nat_gateway.prod-public-nat-gw-euwest1]

  user_data = <<-EOF
#!/bin/bash
sudo apt update

# Add Docker's official GPG key:
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  ${"$"}(. /etc/os-release && echo "${"$"}{UBUNTU_CODENAME:-${"$"}VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

# Install Docker
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Run the container
docker run -d --name mongo \
    -e MONGO_INITDB_ROOT_USERNAME=${var.MONGODB_USER} \
    -e MONGO_INITDB_ROOT_PASSWORD=${var.MONGODB_PASSWORD} \
    -p 27017:27017 \
    mongo
EOF

  tags = {
    Name = "prod-private-ec2-instance-euwest1"
  }
}