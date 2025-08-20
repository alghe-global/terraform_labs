terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 6.9.0"
    }
  }
}

# Create transit gateway for eu-west-1
resource "aws_ec2_transit_gateway" "prod-transit-gateway-euwest1" {
  description = "Transit gateway for public frontend and backend VPCs in eu-west-1"

  tags = {
    Name = "prod-transit-gateway-euwest1"
  }
}

# Frontend Transit Gateway attachment
variable "prod-frontend-vpc-id-euwest1" {
  description = "VPC VPC id for prod frontend in eu-west-1"
}

variable "prod-frontend-subnet-id-euwest1" {
  description = "VPC subnet id for prod frontend in eu-west-1"
}

resource "aws_ec2_transit_gateway_vpc_attachment" "prod-transit-gateway-frontend-attachment-euwest1" {
  subnet_ids = [var.prod-frontend-subnet-id-euwest1]
  transit_gateway_id = aws_ec2_transit_gateway.prod-transit-gateway-euwest1.id
  vpc_id             = var.prod-frontend-vpc-id-euwest1
  depends_on = [aws_ec2_transit_gateway.prod-transit-gateway-euwest1]

  tags = {
    Name = "prod-transit-gateway-frontend-attachment-euwest1"
  }
}

# Backend Transit Gateway attachment
variable "prod-backend-vpc-id-euwest1" {
  description = "VPC VPC id for prod backend in eu-west-1"
}

variable "prod-backend-subnet-id-euwest1" {
  description = "VPC subnet id for prod backend in eu-west-1"
}

resource "aws_ec2_transit_gateway_vpc_attachment" "prod-transit-gateway-backend-attachment-euwest1" {
  subnet_ids = [var.prod-backend-subnet-id-euwest1]
  transit_gateway_id = aws_ec2_transit_gateway.prod-transit-gateway-euwest1.id
  vpc_id             = var.prod-backend-vpc-id-euwest1
  depends_on = [aws_ec2_transit_gateway.prod-transit-gateway-euwest1]

  tags = {
    Name = "prod-transit-gateway-backend-attachment-euwest1"
  }
}

# Update route tables
#####################
# Frontend
variable "CIDR-prod-public-frontend-vpc" {
  description = "Same CIDR used in vpc module for public frontend vpc"
}

variable "prod-public-frontend-rt-id" {
  description = "ID for prod public frontend route table"
}

resource "aws_route" "prod-public-frontend-tgw-route" {
  route_table_id = var.prod-public-frontend-rt-id
  destination_cidr_block = var.CIDR-prod-public-backend-vpc
  transit_gateway_id = aws_ec2_transit_gateway.prod-transit-gateway-euwest1.id
  depends_on = [aws_ec2_transit_gateway_vpc_attachment.prod-transit-gateway-backend-attachment-euwest1]
}

# Backend
variable "CIDR-prod-public-backend-vpc" {
  description = "Same CIDR used in vpc module for public backend vpc"
}

variable "prod-public-backend-rt-id" {
  description = "ID for prod public backend route table"
}

resource "aws_route" "prod-public-backend-tgw-route" {
  route_table_id = var.prod-public-backend-rt-id
  destination_cidr_block = var.CIDR-prod-public-frontend-vpc
  transit_gateway_id = aws_ec2_transit_gateway.prod-transit-gateway-euwest1.id
  depends_on = [aws_ec2_transit_gateway_vpc_attachment.prod-transit-gateway-frontend-attachment-euwest1]
}