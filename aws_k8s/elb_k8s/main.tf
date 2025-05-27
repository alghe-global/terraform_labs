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

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc-euwest1.id

  tags = {
    name = "euwest1 prod igw"
  }
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

resource "aws_lb" "nlb" {
  name               = "nlb"
  load_balancer_type = "network"
  internal           = false
  security_groups    = [aws_security_group.allow_traffic.id]

  subnet_mapping {
    subnet_id     = aws_subnet.subnet-vpc-euwest1.id
  }

  depends_on = [
    aws_instance.web-server-instance,
    aws_lb_target_group.nlb-target-http-group,
    aws_lb_target_group.nlb-target-ssh-group
  ]
}

output "nlb_fqdn" {
  value = aws_lb.nlb.dns_name
}

variable "nlb-listener-http-port" {
  description = "The HTTP port for which the NLB will listen"
}

variable "nlb-listener-http-protocol" {
  description = "The protocol for which the NLB will listen for HTTP traffic"
}

resource "aws_lb_listener" "nlb-listener-http" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = var.nlb-listener-http-port
  protocol          = var.nlb-listener-http-protocol
  depends_on = [aws_lb_target_group.nlb-target-http-group]

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nlb-target-http-group.arn
  }
}

resource "aws_lb_target_group_attachment" "nlb-target-http-group-attachment" {
  target_group_arn = aws_lb_target_group.nlb-target-http-group.arn
  target_id        = aws_instance.web-server-instance.id
  port             = var.nlb-target-group-http-port
  depends_on = [aws_lb_target_group.nlb-target-http-group]
}

variable "nlb-target-group-http-port" {
  description = "The port on which targets listen so that the NLB will route HTTP traffic to them (this is the nodePort)"
}

variable "nlb-target-group-http-protocol" {
  description = "The protocol which we should route HTTP traffic for"
}

resource "aws_lb_target_group" "nlb-target-http-group" {
  name     = "http-ec2-euwest1"
  port     = var.nlb-target-group-http-port
  protocol = var.nlb-target-group-http-protocol
  vpc_id   = aws_vpc.vpc-euwest1.id
}

resource "aws_vpc_security_group_ingress_rule" "allow_ingress-nlb-target-http-group_ipv4" {
  security_group_id = aws_security_group.allow_traffic.id
  cidr_ipv4 = var.allow_ingress-http_cidr
  from_port = var.nlb-target-group-http-port
  ip_protocol = var.allow_ingress-http_protocol
  to_port = var.nlb-target-group-http-port
}

variable "nlb-target-group-ssh-port" {
  description = "The port on which targets listen so that the NLB will route SSH traffic to them (this is the nodePort)"
}

variable "nlb-target-group-ssh-protocol" {
  description = "The protocol which we should route SSH traffic for"
}

resource "aws_lb_target_group" "nlb-target-ssh-group" {
  name     = "ssh-ec2-euwest1"
  port     = var.nlb-target-group-ssh-port
  protocol = var.nlb-target-group-ssh-protocol
  vpc_id   = aws_vpc.vpc-euwest1.id
}

resource "aws_lb_listener" "nlb-listener-ssh" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = var.nlb-target-group-ssh-port
  protocol          = var.nlb-target-group-ssh-protocol
  depends_on = [aws_lb_target_group.nlb-target-ssh-group]

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nlb-target-ssh-group.arn
  }
}

resource "aws_lb_target_group_attachment" "nlb-target-ssh-group-attachment" {
  target_group_arn = aws_lb_target_group.nlb-target-ssh-group.arn
  target_id        = aws_instance.web-server-instance.id
  port             = var.nlb-target-group-ssh-port
  depends_on = [aws_lb_target_group.nlb-target-ssh-group]
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

variable "AWS_EUWEST1_ACCESS_KEY" {
  description = "AWS Access Key in eu-west-1. Set in root main.tf"
}

variable "AWS_EUWEST1_SECRET_KEY" {
  description = "AWS Secret Key in eu-west-1. Set in root main.tf"
}

resource "aws_instance" "web-server-instance" {
  ami           = "ami-0df368112825f8d8f"
  instance_type = "t2.medium"
  availability_zone = "eu-west-1a"
  key_name = "lab"

  depends_on = [aws_eip.eip]  # otherwise, the instance is created without the EIP having been attached

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.nic-1.id
  }

  user_data = <<-EOF
#!/bin/bash
sudo apt update -y

# Install necessary packages for docker and kubectl
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg

# Add Docker's official GPG key
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add Docker repository to Apt sources
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  ${"$"}(. /etc/os-release && echo "${"$"}{UBUNTU_CODENAME:-${"$"}VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Add kubectl repository to Apt sources
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.33/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
sudo chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg # allow unprivileged APT programs to read this keyring

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.33/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo chmod 644 /etc/apt/sources.list.d/kubernetes.list   # helps tools such as command-not-found to work correctly

sudo apt-get update

# Install docker
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Install kubectl
sudo apt install -y kubectl

# Install minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube_latest_amd64.deb
sudo dpkg -i minikube_latest_amd64.deb

# Prepare minikube user
groupadd docker
usermod -aG docker ubuntu
su ubuntu -c 'sudo usermod -aG docker ubuntu && newgrp docker ; cd /home/ubuntu ; minikube start --driver=docker'

# Write configuration for Kubernetes
su ubuntu -c 'cat > /home/ubuntu/aws-secrets.yaml << K8SEOF
apiVersion: v1
kind: Secret
metadata:
  name: aws-secrets
type: Opaque
data:
  aws_access_key_id: ${base64encode(var.AWS_EUWEST1_ACCESS_KEY)}
  aws_secret_access_key: ${base64encode(var.AWS_EUWEST1_SECRET_KEY)}
K8SEOF'

su ubuntu -c 'cat > /home/ubuntu/dynamodb-app.yaml << K8SEOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: dynamodb-app
  labels:
    app: dynamodb-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: dynamodb-app
  template:
    metadata:
      labels:
        app: dynamodb-app
    spec:
      containers:
      - name: dynamodb-app
        image: algheglobal/aws_k8s:1.0
        ports:
        - containerPort: 5000
        env:
        - name: AWS_ACCESS_KEY_ID
          valueFrom:
            secretKeyRef:
              name: aws-secrets
              key: aws_access_key_id
        - name: AWS_SECRET_ACCESS_KEY
          valueFrom:
            secretKeyRef:
              name: aws-secrets
              key: aws_secret_access_key
        - name: AWS_REGION
          value: us-east-1
        - name: AWS_DYNAMODB_TABLE
          value: hello
        - name: AWS_DYNAMODB_KEY
          value: message
        - name: AWS_DYNAMODB_VALUE
          value: Hello, world!
---
apiVersion: v1
kind: Service
metadata:
  name: dynamodb-app-service
spec:
  selector:
    app: dynamodb-app
  type: LoadBalancer
  loadBalancerSourceRanges:
  - 10.0.1.50/32
  ports:
    - protocol: TCP
      port: 80
      targetPort: 5000
      nodePort: 30000
K8SEOF'

# Apply K8s configuration
su ubuntu -c 'kubectl apply -f /home/ubuntu/aws-secrets.yaml'
su ubuntu -c 'kubectl apply -f /home/ubuntu/dynamodb-app.yaml'

# Route traffic to the NodePort service
su ubuntu -c 'sleep 60; kubectl port-forward --address=${var.eip_private_ip} services/dynamodb-app-service 30000:80 &'
EOF

  tags = {
    Name = "prod-web-server"
  }
}
