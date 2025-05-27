terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.98.0"
    }
  }
}

variable "cidr_vpc-euwest1" {
  description = "CIDR block for VPC in eu-west-1 connecting ELB"
}

resource "aws_vpc" "vpc-euwest1" {
  cidr_block = var.cidr_vpc-euwest1

  tags = {
    Name = "prod-vpc-euwest1"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc-euwest1.id
}

variable "cidr_subnet-vpc-euwest1" {
  description = "CIDR block for subnet in VPC in eu-west-1 connecting ELB"
}

variable "cidr_subnet-vpc-euwest1-az" {
  description = "Availability Zone to have the VPC subnet in eu-west-1 part of"
}

resource "aws_subnet" "subnet-vpc-euwest1" {
  vpc_id = aws_vpc.vpc-euwest1.id
  cidr_block = var.cidr_subnet-vpc-euwest1
  availability_zone = var.cidr_subnet-vpc-euwest1-az

  tags = {
    Name = "prod"
  }
}

resource "aws_security_group" "allow_traffic" {
  name = "allow_traffic"
  description = "Allow HTTP and SSH inbound traffic and all outbound traffic"
  vpc_id = aws_vpc.vpc-euwest1.id

  tags = {
    Name = "allow_traffic"
  }
}

variable "allow_ingress-http_cidr" {
  description = "CIDR block to allow IPv4 traffic to the ELB"
}

variable "allow_ingress-http_from_port" {
  description = "From port to be allowed to the ELB"
}

variable "allow_ingress-http_to_port" {
  description = "To port to be allowed to the ELB"
}

variable "allow_ingress-http_protocol" {
  description = "Which protocol is to be allowed for the traffic"
}

resource "aws_vpc_security_group_ingress_rule" "allow_ingress-http_ipv4" {
  security_group_id = aws_security_group.allow_traffic.id
  cidr_ipv4 = var.allow_ingress-http_cidr
  from_port = var.allow_ingress-http_from_port
  ip_protocol = var.allow_ingress-http_protocol
  to_port = var.allow_ingress-http_to_port
}

variable "allow_ingress-ssh_cidr" {
  description = "CIDR block to allow SSH IPv4 traffic to the ELB"
}

variable "allow_ingress-ssh_from_port" {
  description = "From port to be allowed to the ELB"
}

variable "allow_ingress-ssh_to_port" {
  description = "To port to be allowed to the ELB"
}

variable "allow_ingress-ssh_protocol" {
  description = "Which protocol is to be allowed for the traffic"
}

resource "aws_vpc_security_group_ingress_rule" "allow_ingress-ssh_ipv4" {
  security_group_id = aws_security_group.allow_traffic.id
  cidr_ipv4 = var.allow_ingress-ssh_cidr
  from_port = var.allow_ingress-ssh_from_port
  ip_protocol = var.allow_ingress-ssh_protocol
  to_port = var.allow_ingress-ssh_to_port
}

variable "allow_egress_cidr" {
  description = "CIDR block for all egress IPv4 traffic"
}

variable "allow_egress_protocol" {
  description = "Protocol allowed for all egress IPv4 traffic"
}

resource "aws_vpc_security_group_egress_rule" "allow_egress-all_ipv4" {
  security_group_id = aws_security_group.allow_traffic.id
  cidr_ipv4 = var.allow_egress_cidr
  ip_protocol = var.allow_egress_protocol
}

resource "aws_network_interface" "nic-1" {
  subnet_id = aws_subnet.subnet-vpc-euwest1.id
  private_ips = [var.eip_private_ip]
  security_groups = [aws_security_group.allow_traffic.id]
}

variable "eip_private_ip" {
  description = "The private IP in subnet to associate the EIP with"
}

resource "aws_eip" "eip" {
  domain = "vpc"
  network_interface = aws_network_interface.nic-1.id
  associate_with_private_ip = var.eip_private_ip
  depends_on = [aws_internet_gateway.gw]  # create the EIP only after the gateway exists
}

output "ec2_instance_public_ip" {
  value = aws_eip.eip.public_ip
}

variable "prod-euwest-1-route-table-cidr" {
  description = "The CIDR block to assign to the route table"
}

# Route all traffic in subnet `cidr_vpc-euwest' of `vpc-euwest1' to `nic-1'
resource "aws_route_table" "prod-euwest-1-route-table" {
  vpc_id = aws_vpc.vpc-euwest1.id

  route {
    cidr_block = var.prod-euwest-1-route-table-cidr
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "prod"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id = aws_subnet.subnet-vpc-euwest1.id
  route_table_id = aws_route_table.prod-euwest-1-route-table.id
}

variable "AWS_EUWEST1_ACCESS_KEY" {
  description = "AWS Access Key in eu-west-1 for the app. To be used for setting environment variable for docker."
}

variable "AWS_EUWEST1_SECRET_KEY" {
  description = "AWS Secret Key in eu-west-1 for the app. To be used for setting environment variable for docker."
}

resource "aws_instance" "web-server-instance" {
  ami           = "ami-0df368112825f8d8f"
  instance_type = "t2.micro"
  availability_zone = "eu-west-1a"
  key_name = "lab"

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.nic-1.id
  }

  user_data = <<-EOF
#!/bin/bash
sudo apt update -y
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

sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Run the container
docker run -e AWS_ACCESS_KEY_ID="${var.AWS_EUWEST1_ACCESS_KEY}" -e AWS_SECRET_ACCESS_KEY="${var.AWS_EUWEST1_SECRET_KEY}" -e AWS_REGION="us-east-1" -e AWS_DYNAMODB_TABLE="hello" -e AWS_DYNAMODB_KEY="message" -e AWS_DYNAMODB_VALUE="Hello, world!" --name aws_k8s -d -p 80:5000 algheglobal/aws_k8s:1.0
EOF

  tags = {
    Name = "prod-web-server"
  }
}
