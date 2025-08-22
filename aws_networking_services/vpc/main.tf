variable "MONGODB_USER" {
  description = "MongoDB user to use when setting up both frontend and backend"
}

variable "MONGODB_PASSWORD" {
  description = "MongoDB password to use when setting up both frontend and backend"
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 6.9.0"
    }
  }
}

variable "CIDR-prod-vpc-euwest1" {
  description = "CIDR to use for VPC in prod eu-west-1"
}

resource "aws_vpc" "prod-vpc-euwest1" {
  cidr_block = var.CIDR-prod-vpc-euwest1

  tags = {
    Name = "prod-vpc-euwest1"
  }
}

output "prod-vpc-euwest1-id" {
  value = aws_vpc.prod-vpc-euwest1.id
}

resource "aws_internet_gateway" "prod-vpc-igw-euwest1" {
  vpc_id = aws_vpc.prod-vpc-euwest1.id

  tags = {
    Name = "prod-vpc-igw-euwest1"
  }
}

###############################################
# 1: Public and private of frontend and backend
###############################################

resource "aws_route_table" "prod-rt-igw-a-euwest1" {
  vpc_id = aws_vpc.prod-vpc-euwest1.id

  tags = {
    Name = "prod-rt-igw-a-euwest1"
  }
}

variable "CIDR-prod-route-igw-euwest1" {
  description = "CIDR block for prod a route for internet gateway in eu-west-1"
}

resource "aws_route" "prod-rt-igw-a-route-euwest1" {
  route_table_id = aws_route_table.prod-rt-igw-a-euwest1.id
  destination_cidr_block = var.CIDR-prod-route-igw-euwest1
  gateway_id = aws_internet_gateway.prod-vpc-igw-euwest1.id
}

variable "CIDR-prod-frontend-public-subnet-a1-euwest1" {
  description = "CIDR for public subnet (a1) of frontend in eu-west-1"
}

output "prod-frontend-public-subnet-a1-euwest1-id" {
  value = aws_subnet.prod-frontend-public-subnet-a1-euwest1.id
}

resource "aws_subnet" "prod-frontend-public-subnet-a1-euwest1" {
  vpc_id = aws_vpc.prod-vpc-euwest1.id
  cidr_block = var.CIDR-prod-frontend-public-subnet-a1-euwest1
  availability_zone = "eu-west-1a"

  tags = {
    Name = "prod-frontend-public-subnet-a1-euwest1"
  }
}

resource "aws_route_table_association" "prod-rt-igw-a-route-association-euwest1" {
  route_table_id = aws_route_table.prod-rt-igw-a-euwest1.id
  subnet_id = aws_subnet.prod-frontend-public-subnet-a1-euwest1.id
}

resource "aws_eip" "prod-backend-private-a2-ngw-euwest1-eip" {
  domain = "vpc"

  tags = {
    Name = "prod-backend-private-a2-ngw-euwest1-eip"
  }
}

resource "aws_nat_gateway" "prod-backend-private-a2-ngw-euwest1" {
  subnet_id = aws_subnet.prod-frontend-public-subnet-a1-euwest1.id
  allocation_id = aws_eip.prod-backend-private-a2-ngw-euwest1-eip.id

  tags = {
    Name = "prod-backend-private-a2-ngw-euwest1"
  }
}

resource "aws_route_table" "prod-rt-ngw-a2-euwest1" {
  vpc_id = aws_vpc.prod-vpc-euwest1.id

  tags = {
    Name = "prod-rt-ngw-a2-euwest1"
  }
}
resource "aws_route" "prod-rt-ngw-b1-route-euwest1" {
  route_table_id = aws_route_table.prod-rt-ngw-a2-euwest1.id
  destination_cidr_block = var.CIDR-prod-route-igw-euwest1
  nat_gateway_id = aws_nat_gateway.prod-backend-private-a2-ngw-euwest1.id
}

resource "aws_route_table_association" "prod-rt-ngw-b2-route-association-euwest1" {
  route_table_id = aws_route_table.prod-rt-ngw-a2-euwest1.id
  subnet_id = aws_subnet.prod-backend-private-subnet-a2-euwest1.id
}

variable "CIDR-prod-backend-private-subnet-a2-euwest1" {
  description = "CIDR for private subnet (a2) of backend in eu-west-1"
}

resource "aws_subnet" "prod-backend-private-subnet-a2-euwest1" {
  vpc_id = aws_vpc.prod-vpc-euwest1.id
  cidr_block = var.CIDR-prod-backend-private-subnet-a2-euwest1
  availability_zone = "eu-west-1a"

  tags = {
    Name = "prod-backend-private-subnet-a2-euwest1"
  }
}

resource "aws_security_group" "prod-frontend-public-a1-sg-euwest1" {
  name = "prod-frontend-public-a1-sg-euwest1"
  description = "Security Group for frontend public in eu-west-1a (a1) EC2 instance allowing SSH and HTTP"
  vpc_id = aws_vpc.prod-vpc-euwest1.id

  tags = {
    Name = "prod-frontend-public-a1-sg-euwest1"
  }
}

variable "port-ingress-http-prod-frontend-public-a1-euwest1" {
  description = "FROM and TO port for HTTP for prod frontend public a1 in eu-west-1"
}

resource "aws_vpc_security_group_ingress_rule" "prod-frontend-public-a1-ingress-http-euwest1" {
  cidr_ipv4         = var.CIDR-prod-route-igw-euwest1
  from_port         = var.port-ingress-http-prod-frontend-public-a1-euwest1
  ip_protocol       = "tcp"
  security_group_id = aws_security_group.prod-frontend-public-a1-sg-euwest1.id
  to_port           = var.port-ingress-http-prod-frontend-public-a1-euwest1

  tags = {
    Name = "prod-frontend-public-a1-ingress-http-euwest1"
  }
}

variable "port-ingress-ssh-prod-frontend-public-a1-euwest1" {
  description = "FROM and TO port for SSH for prod frontend public a1 in eu-west-1"
}

resource "aws_vpc_security_group_ingress_rule" "prod-frontend-public-a1-ingress-ssh-euwest1" {
  cidr_ipv4         = var.CIDR-prod-route-igw-euwest1
  from_port         = var.port-ingress-ssh-prod-frontend-public-a1-euwest1
  ip_protocol       = "tcp"
  security_group_id = aws_security_group.prod-frontend-public-a1-sg-euwest1.id
  to_port           = var.port-ingress-ssh-prod-frontend-public-a1-euwest1
}

resource "aws_vpc_security_group_egress_rule" "prod-frontend-public-a1-egress-euwest1" {
  cidr_ipv4         = var.CIDR-prod-route-igw-euwest1
  ip_protocol       = "-1"
  security_group_id = aws_security_group.prod-frontend-public-a1-sg-euwest1.id
}

output "prod-frontend-public-a1-ec2-instance-euwest1" {
  value = aws_instance.prod-frontend-public-a1-ec2-instance-euwest1
}

output "prod-frontend-public-a1-ec2-instance-euwest1-id" {
  value = aws_instance.prod-frontend-public-a1-ec2-instance-euwest1.id
}

resource "aws_instance" "prod-frontend-public-a1-ec2-instance-euwest1" {
  ami = "ami-0bc691261a82b32bc"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.prod-frontend-public-subnet-a1-euwest1.id
  key_name = "lab"
  associate_public_ip_address = true
  security_groups = [aws_security_group.prod-frontend-public-a1-sg-euwest1.id]
  depends_on = [aws_internet_gateway.prod-vpc-igw-euwest1]

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
    -e MONGODB_HOST=${aws_lb.prod-backend-private-nlb-euwest1.dns_name} \
    -p 80:80 \
    algheglobal/aws_vpc:latest
EOF

  tags = {
    Name = "prod-frontend-public-a1-ec2-instance-euwest1"
  }
}

resource "aws_security_group" "prod-backend-private-a2-sg-euwest1" {
  name = "prod-backend-private-a2-sg-euwest1"
  description = "Security Group for backend private in eu-west-1a (a2) EC2 instance allowing SSH and Mongo"
  vpc_id = aws_vpc.prod-vpc-euwest1.id

  tags = {
    Name = "prod-backend-private-a2-sg-euwest1"
  }
}

variable "port-ingress-mongo-prod-backend-private-a2-euwest1" {
  description = "FROM and TO port for Mongo for prod backend private a2 in eu-west-1"
}

resource "aws_vpc_security_group_ingress_rule" "prod-backend-private-a2-ingress-mongo-euwest1" {
  cidr_ipv4         = var.CIDR-prod-route-igw-euwest1
  from_port         = var.port-ingress-mongo-prod-backend-private-a2-euwest1
  ip_protocol       = "tcp"
  security_group_id = aws_security_group.prod-backend-private-a2-sg-euwest1.id
  to_port           = var.port-ingress-mongo-prod-backend-private-a2-euwest1
}

resource "aws_vpc_security_group_ingress_rule" "prod-backend-private-a2-ingress-ssh-euwest1" {
  cidr_ipv4         = var.CIDR-prod-route-igw-euwest1
  from_port         = var.port-ingress-ssh-prod-frontend-public-a1-euwest1
  ip_protocol       = "tcp"
  security_group_id = aws_security_group.prod-backend-private-a2-sg-euwest1.id
  to_port           = var.port-ingress-ssh-prod-frontend-public-a1-euwest1
}

resource "aws_vpc_security_group_egress_rule" "prod-backend-private-a2-egress-euwest1" {
  cidr_ipv4         = var.CIDR-prod-route-igw-euwest1
  ip_protocol       = "-1"
  security_group_id = aws_security_group.prod-backend-private-a2-sg-euwest1.id
}

resource "aws_instance" "prod-backend-private-a1-ec2-instance-euwest1" {
  ami = "ami-0bc691261a82b32bc"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.prod-backend-private-subnet-a2-euwest1.id
  key_name = "lab"
  security_groups = [aws_security_group.prod-backend-private-a2-sg-euwest1.id]
  depends_on = [aws_nat_gateway.prod-backend-private-a2-ngw-euwest1]

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
    Name = "prod-backend-private-a1-ec2-instance-euwest1"
  }
}

###############################################
# 2: Public and private of frontend and backend
###############################################

resource "aws_route_table" "prod-rt-igw-b-euwest1" {
  vpc_id = aws_vpc.prod-vpc-euwest1.id

  tags = {
    Name = "prod-rt-igw-b-euwest1"
  }
}

resource "aws_route" "prod-rt-igw-b-route-euwest1" {
  route_table_id = aws_route_table.prod-rt-igw-b-euwest1.id
  destination_cidr_block = var.CIDR-prod-route-igw-euwest1
  gateway_id = aws_internet_gateway.prod-vpc-igw-euwest1.id
}

variable "CIDR-prod-frontend-public-subnet-b1-euwest1" {
  description = "CIDR for public subnet (b1) of frontend in eu-west-1"
}

output "prod-frontend-public-subnet-b1-euwest1-id" {
  value = aws_subnet.prod-frontend-public-subnet-b1-euwest1.id
}

resource "aws_subnet" "prod-frontend-public-subnet-b1-euwest1" {
  vpc_id = aws_vpc.prod-vpc-euwest1.id
  cidr_block = var.CIDR-prod-frontend-public-subnet-b1-euwest1
  availability_zone = "eu-west-1b"

  tags = {
    Name = "prod-frontend-public-subnet-b1-euwest1"
  }
}

resource "aws_route_table_association" "prod-rt-igw-b-route-association-euwest1" {
  route_table_id = aws_route_table.prod-rt-igw-b-euwest1.id
  subnet_id = aws_subnet.prod-frontend-public-subnet-b1-euwest1.id
}

resource "aws_eip" "prod-backend-private-b2-ngw-euwest1-eip" {
  domain = "vpc"

  tags = {
    Name = "prod-backend-private-b2-ngw-euwest1-eip"
  }
}

resource "aws_nat_gateway" "prod-backend-private-b2-ngw-euwest1" {
  subnet_id = aws_subnet.prod-frontend-public-subnet-b1-euwest1.id
  allocation_id = aws_eip.prod-backend-private-b2-ngw-euwest1-eip.id

  tags = {
    Name = "prod-backend-private-b2-ngw-euwest1"
  }
}

resource "aws_route_table" "prod-rt-ngw-b2-euwest1" {
  vpc_id = aws_vpc.prod-vpc-euwest1.id

  tags = {
    Name = "prod-rt-ngw-b2-euwest1"
  }
}

resource "aws_route" "prod-rt-ngw-b2-route-euwest1" {
  route_table_id = aws_route_table.prod-rt-ngw-b2-euwest1.id
  destination_cidr_block = var.CIDR-prod-route-igw-euwest1
  nat_gateway_id = aws_nat_gateway.prod-backend-private-a2-ngw-euwest1.id
}

resource "aws_route_table_association" "prod-rt-ngw-b1-route-association-euwest1" {
  route_table_id = aws_route_table.prod-rt-ngw-b2-euwest1.id
  subnet_id = aws_subnet.prod-backend-private-subnet-b2-euwest1.id
}

variable "CIDR-prod-backend-private-subnet-b2-euwest1" {
  description = "CIDR for private subnet (b2) of backend in eu-west-1"
}

resource "aws_subnet" "prod-backend-private-subnet-b2-euwest1" {
  vpc_id = aws_vpc.prod-vpc-euwest1.id
  cidr_block = var.CIDR-prod-backend-private-subnet-b2-euwest1
  availability_zone = "eu-west-1b"

  tags = {
    Name = "prod-backend-private-subnet-b2-euwest1"
  }
}

output "prod-frontend-public-b1-ec2-instance-euwest1" {
  value = aws_instance.prod-frontend-public-b1-ec2-instance-euwest1
}

output "prod-frontend-public-b1-ec2-instance-euwest1-id" {
  value = aws_instance.prod-frontend-public-b1-ec2-instance-euwest1.id
}

resource "aws_instance" "prod-frontend-public-b1-ec2-instance-euwest1" {
  subnet_id = aws_subnet.prod-frontend-public-subnet-b1-euwest1.id
  associate_public_ip_address = true
  security_groups = [aws_security_group.prod-frontend-public-a1-sg-euwest1.id]
  depends_on = [aws_internet_gateway.prod-vpc-igw-euwest1]

  launch_template {
    id = aws_launch_template.prod-frontend-public-ec2-instance-launch-template-euwest1.id
    version = "$Latest"
  }

  tags = {
    Name = "prod-frontend-public-b1-ec2-instance-euwest1"
  }
}

resource "aws_instance" "prod-backend-private-b1-ec2-instance-euwest1" {
  subnet_id = aws_subnet.prod-backend-private-subnet-b2-euwest1.id
  depends_on = [aws_nat_gateway.prod-backend-private-b2-ngw-euwest1]

  launch_template {
    id = aws_launch_template.prod-backend-private-ec2-instance-launch-template-euwest1.id
    version = "$Latest"
  }

  tags = {
    Name = "prod-backend-private-b1-ec2-instance-euwest1"
  }
}

##################
# Launch templates
##################

resource "aws_launch_template" "prod-frontend-public-ec2-instance-launch-template-euwest1" {
  image_id = "ami-0bc691261a82b32bc"
  instance_type = "t2.micro"
  key_name = "lab"

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "prod-frontend-public-ec2-lt"
    }
  }

  user_data = base64encode(
    templatefile(
      "${path.module}/frontend_user_data.sh",
      {
        MONGODB_USER                                     = var.MONGODB_USER,
        MONGODB_PASSWORD                                 = var.MONGODB_PASSWORD,
        aws_lb-prod-backend-private-nlb-euwest1-dns_name = aws_lb.prod-backend-private-nlb-euwest1.dns_name
      }
    )
  )
}

resource "aws_launch_template" "prod-backend-private-ec2-instance-launch-template-euwest1" {
  image_id = "ami-0bc691261a82b32bc"
  instance_type = "t2.micro"
  key_name = "lab"
  vpc_security_group_ids = [aws_security_group.prod-backend-private-a2-sg-euwest1.id]

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "prod-backend-private-ec2-lt"
    }
  }

  user_data = base64encode(
    templatefile(
      "${path.module}/backend_user_data.sh",
      {
        MONGODB_USER=var.MONGODB_USER,
        MONGODB_PASSWORD=var.MONGODB_PASSWORD
      }
    )
  )
}

###############################
# Backend Network Load Balancer
###############################

resource "aws_security_group" "prod-backend-private-nlb-sg-euwest1" {
  description = "Security Group for prod backend private NLB in eu-west-1"
  vpc_id = aws_vpc.prod-vpc-euwest1.id

  tags = {
    Name = "prod-backend-private-nlb-sg-euwest1"
  }
}

resource "aws_vpc_security_group_ingress_rule" "prod-backend-private-nlb-ingress-euwest1" {
  cidr_ipv4         = var.CIDR-prod-route-igw-euwest1
  from_port         = var.port-ingress-mongo-prod-backend-private-a2-euwest1
  ip_protocol       = "tcp"
  security_group_id = aws_security_group.prod-backend-private-nlb-sg-euwest1.id
  to_port           = var.port-ingress-mongo-prod-backend-private-a2-euwest1
}

resource "aws_vpc_security_group_egress_rule" "prod-backend-private-nlb-egress-euwest1" {
  cidr_ipv4         = var.CIDR-prod-route-igw-euwest1
  ip_protocol       = "-1"
  security_group_id = aws_security_group.prod-backend-private-nlb-sg-euwest1.id
}

resource "aws_lb_target_group" "prod-backend-private-nlb-tg-euwest1" {
  name        = "prod-backend-priv-nlb-tg-euwest1"
  port        = var.port-ingress-mongo-prod-backend-private-a2-euwest1
  protocol    = "TCP"
  vpc_id      = aws_vpc.prod-vpc-euwest1.id

  health_check {
    port = var.port-ingress-mongo-prod-backend-private-a2-euwest1
    protocol = "TCP"
    timeout = 30  # XXX: we need to be relaxed here as there may be delay due to docker start-up
  }

  tags = {
    Name = "prod-backend-private-nlb-tg-euwest1"
  }
}

resource "aws_lb_target_group_attachment" "prod-backend-private-nlb-tg-attachment-a2-euwest1" {
  target_group_arn = aws_lb_target_group.prod-backend-private-nlb-tg-euwest1.arn
  target_id        = aws_instance.prod-backend-private-a1-ec2-instance-euwest1.id
  port             = var.port-ingress-mongo-prod-backend-private-a2-euwest1
  depends_on       = [aws_lb_target_group.prod-backend-private-nlb-tg-euwest1]
}

resource "aws_lb_target_group_attachment" "prod-backend-private-nlb-tg-attachment-b2-euwest1" {
  target_group_arn = aws_lb_target_group.prod-backend-private-nlb-tg-euwest1.arn
  target_id        = aws_instance.prod-backend-private-b1-ec2-instance-euwest1.id
  port             = var.port-ingress-mongo-prod-backend-private-a2-euwest1
  depends_on       = [aws_lb_target_group.prod-backend-private-nlb-tg-euwest1]
}

resource "aws_lb_listener" "prod-backend-nlb-listener-mongo-euwest1" {
  load_balancer_arn = aws_lb.prod-backend-private-nlb-euwest1.arn
  port              = var.port-ingress-mongo-prod-backend-private-a2-euwest1
  protocol          = "TCP"
  depends_on = [aws_lb_target_group.prod-backend-private-nlb-tg-euwest1]

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.prod-backend-private-nlb-tg-euwest1.arn
  }
}

resource "aws_lb" "prod-backend-private-nlb-euwest1" {
  name = "prod-backend-private-nlb-euwest1"
  internal = true
  load_balancer_type = "network"
  security_groups = [aws_security_group.prod-backend-private-nlb-sg-euwest1.id]
  subnets = [aws_subnet.prod-backend-private-subnet-a2-euwest1.id, aws_subnet.prod-backend-private-subnet-b2-euwest1.id]

  depends_on = [
    aws_instance.prod-backend-private-a1-ec2-instance-euwest1,
    aws_instance.prod-backend-private-b1-ec2-instance-euwest1,
    aws_lb_target_group.prod-backend-private-nlb-tg-euwest1
  ]

  tags = {
    Name = "prod-backend-private-nlb-euwest1"
  }
}