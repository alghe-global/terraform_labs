terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "= 6.9.0"
    }
  }
}

variable "CIDR-prod-public-frontend-vpc" {
  description = "CIDR for prod public frontend VPC in eu-west-1"
}

# Create VPC, subnet, IGW, route table and security group for public frontend
resource "aws_vpc" "prod-public-frontend-vpc" {
  cidr_block = var.CIDR-prod-public-frontend-vpc

  tags = {
    Name = "prod-public-frontend-vpc"
  }
}

output "prod-frontend-vpc-id-euwest1" {
  value = aws_vpc.prod-public-frontend-vpc.id
}

variable "CIDR-prod-public-frontend-subnet" {
  description = "CIDR for public frontend subnet"
}

resource "aws_subnet" "prod-public-frontend-subnet" {
  vpc_id = aws_vpc.prod-public-frontend-vpc.id
  cidr_block = var.CIDR-prod-public-frontend-subnet
  availability_zone = "eu-west-1a"

  tags = {
    Name = "prod-public-frontend-subnet"
  }
}

output "prod-frontend-subnet-id-euwest1" {
  value = aws_subnet.prod-public-frontend-subnet.id
}

resource "aws_internet_gateway" "prod-public-frontend-igw" {
  vpc_id = aws_vpc.prod-public-frontend-vpc.id

  tags = {
    Name = "prod-public-frontend-igw"
  }
}

resource "aws_route_table" "prod-public-frontend-rt" {
  vpc_id = aws_vpc.prod-public-frontend-vpc.id

  tags = {
    Name = "prod-public-frontend-rt"
  }
}

output "prod-public-frontend-rt-id" {
  value = aws_route_table.prod-public-frontend-rt.id
}

resource "aws_route" "prod-public-frontend-rt-igw-route" {
  route_table_id = aws_route_table.prod-public-frontend-rt.id
  destination_cidr_block = var.egress-cidr-public-frontend
  gateway_id = aws_internet_gateway.prod-public-frontend-igw.id
}

resource "aws_route_table_association" "prod-public-frontend-rt-association" {
  subnet_id = aws_subnet.prod-public-frontend-subnet.id
  route_table_id = aws_route_table.prod-public-frontend-rt.id
}

resource "aws_security_group" "prod-public-frontend-sg" {
  name = "prod-public-frontend-sg"
  description = "Allow HTTP and SSH traffic to prod public frontend in eu-west-1"
  vpc_id = aws_vpc.prod-public-frontend-vpc.id

  tags = {
    Name = "prod-public-frontend-sg"
  }
}

variable "ingress-http-ssh-cidr-prod-public-frontend" {
  description = "CIDR for both HTTP and SSH ingress rules for public frontend"
}

variable "ingress-http-from-to-port-prod-public-frontend" {
  description = "FROM and TO port for HTTP ingress rule for public frontend"
}

variable "ingress-ssh-from-to-port-prod-public-frontend" {
  description = "FROM and TO port for SSH ingress rule for public frontend"
}

resource "aws_vpc_security_group_ingress_rule" "prod-public-http-frontend-ingress" {
  security_group_id = aws_security_group.prod-public-frontend-sg.id

  cidr_ipv4 = var.ingress-http-ssh-cidr-prod-public-frontend
  from_port = var.ingress-http-from-to-port-prod-public-frontend
  ip_protocol = "tcp"
  to_port = var.ingress-http-from-to-port-prod-public-frontend
}

resource "aws_vpc_security_group_ingress_rule" "prod-public-ssh-frontend-ingress" {
  security_group_id = aws_security_group.prod-public-frontend-sg.id

  cidr_ipv4 = var.ingress-http-ssh-cidr-prod-public-frontend
  from_port = var.ingress-ssh-from-to-port-prod-public-frontend
  ip_protocol = "tcp"
  to_port = var.ingress-ssh-from-to-port-prod-public-frontend
}

variable "egress-cidr-public-frontend" {
  description = "CIDR for egress rule for public frontend"
}

variable "egress-from-to-port-public-frontend" {
  description = "FROM and TO port for egress rule for public frontend"
}

resource "aws_vpc_security_group_egress_rule" "prod-public-frontend-egress" {
  security_group_id = aws_security_group.prod-public-frontend-sg.id

  cidr_ipv4 = var.egress-cidr-public-frontend
  from_port = var.egress-from-to-port-public-frontend
  ip_protocol = "-1"
  to_port = var.egress-from-to-port-public-frontend
}

# Create VPC, subnet, IGW, route table and security group for public backend
variable "CIDR-prod-public-backend-vpc" {
  description = "CIDR for prod public backend VPC in eu-west-1"
}

resource "aws_vpc" "prod-public-backend-vpc" {
  cidr_block = var.CIDR-prod-public-backend-vpc

  tags = {
    Name = "prod-public-backend-vpc"
  }
}

output "prod-backend-vpc-id-euwest1" {
  value = aws_vpc.prod-public-backend-vpc.id
}

variable "CIDR-prod-public-backend-subnet" {
  description = "CIDR for public backendend subnet"
}

resource "aws_subnet" "prod-public-backend-subnet" {
  vpc_id = aws_vpc.prod-public-backend-vpc.id
  cidr_block = var.CIDR-prod-public-backend-subnet
  availability_zone = "eu-west-1b"

  tags = {
    Name = "prod-public-backend-subnet"
  }
}

output "prod-backend-subnet-id-euwest1" {
  value = aws_subnet.prod-public-backend-subnet.id
}

resource "aws_internet_gateway" "prod-public-backend-igw" {
  vpc_id = aws_vpc.prod-public-backend-vpc.id

  tags = {
    Name = "prod-public-backend-igw"
  }
}

resource "aws_route_table" "prod-public-backend-rt" {
  vpc_id = aws_vpc.prod-public-backend-vpc.id

  tags = {
    Name = "prod-public-backend-rt"
  }
}

output "prod-public-backend-rt-id" {
  value = aws_route_table.prod-public-backend-rt.id
}

resource "aws_route" "prod-public-backend-rt-igw-route" {
  route_table_id = aws_route_table.prod-public-backend-rt.id
  destination_cidr_block = var.egress-cidr-public-frontend
  gateway_id = aws_internet_gateway.prod-public-backend-igw.id
}

resource "aws_route_table_association" "prod-public-backend-rt-association" {
  subnet_id = aws_subnet.prod-public-backend-subnet.id
  route_table_id = aws_route_table.prod-public-backend-rt.id
}

resource "aws_security_group" "prod-public-backend-sg" {
  name = "prod-public-backend-sg"
  description = "Allow MongoDB traffic to prod public backend in eu-west-1"
  vpc_id = aws_vpc.prod-public-backend-vpc.id

  tags = {
    Name = "prod-public-backend-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "prod-public-ssh-backend-ingress" {
  security_group_id = aws_security_group.prod-public-backend-sg.id

  cidr_ipv4 = var.ingress-http-ssh-cidr-prod-public-frontend
  from_port = var.ingress-ssh-from-to-port-prod-public-frontend
  ip_protocol = "tcp"
  to_port = var.ingress-ssh-from-to-port-prod-public-frontend
}

variable "CIDR-ingress-prod-public-backend" {
  description = "CIDR for ingress rule for prod public backend in eu-west-1"
}

variable "ingress-mongo-from-to-port-prod-public-backend" {
  description = "FROM and TO port for ingress rule for prod public backend in eu-west-1"
}

resource "aws_vpc_security_group_ingress_rule" "prod-public-mongo-backend-ingress" {
  security_group_id = aws_security_group.prod-public-backend-sg.id

  cidr_ipv4 = var.CIDR-ingress-prod-public-backend
  from_port = var.ingress-mongo-from-to-port-prod-public-backend
  ip_protocol = "tcp"
  to_port = var.ingress-mongo-from-to-port-prod-public-backend
}

variable "CIDR-egress-prod-public-backend" {
  description = "CIDR for egress rule for prod public backend in eu-west-1"
}

variable "egress-from-to-port-public-backend" {
  description = "FROM and TO port for egress rule for prod public backend in eu-west-1"
}

resource "aws_vpc_security_group_egress_rule" "prod-public-backend-egress" {
  security_group_id = aws_security_group.prod-public-backend-sg.id

  cidr_ipv4 = var.CIDR-egress-prod-public-backend
  from_port = var.egress-from-to-port-public-backend
  ip_protocol = "-1"
  to_port = var.egress-from-to-port-public-backend
}

# Create EC2 instances for both prod public frontend and backend instances
variable "MONGODB_USER" {
  description = "What MongoDB user to use when connecting to backend"
}

variable "MONGODB_PASSWORD" {
  description = "What MongoDB password to sue when connecting to backend"
}

variable "prod-public-frontend-ec2-instance-euwest1-private-ip" {
  description = "Private IP address of prod public frontend EC2 instance in eu-west-1"
}

resource "aws_instance" "prod-public-frontend-ec2-instance" {
  ami = "ami-01f23391a59163da9"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.prod-public-frontend-subnet.id
  associate_public_ip_address = true
  security_groups = [aws_security_group.prod-public-frontend-sg.id]
  private_ip = var.prod-public-frontend-ec2-instance-euwest1-private-ip
  key_name = "lab"
  depends_on = [aws_internet_gateway.prod-public-frontend-igw]

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
    -e MONGODB_HOST=${var.prod-public-backend-ec2-instance-euwest1-private-ip} \
    -p 80:80 \
    algheglobal/aws_vpc:latest
EOF

  tags = {
    Name = "prod-public-frontend-ec2-instance"
  }
}

variable "prod-public-backend-ec2-instance-euwest1-private-ip" {
  description = "Private IP address of prod public backend EC2 instance in eu-west-1"
}

resource "aws_instance" "prod-public-backend-ec2-instance" {
  ami = "ami-01f23391a59163da9"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.prod-public-backend-subnet.id
  associate_public_ip_address = true  # NOTE: NEVER MAKE YOUR BACKEND PUBLIC!
  security_groups = [aws_security_group.prod-public-backend-sg.id]
  private_ip = var.prod-public-backend-ec2-instance-euwest1-private-ip
  key_name = "lab"
  depends_on = [aws_internet_gateway.prod-public-backend-igw]

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
    Name = "prod-public-backend-ec2-instance"
  }
}