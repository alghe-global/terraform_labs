terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 6.9.0"
    }
  }
}

variable "prod-private-frontend-peer-vpc-id-eucentral1" {
  description = "Peer VPC ID for prod private frontend in eu-central-1"
}

variable "prod-public-frontend-vpc-id-euwest1" {
  description = "VPC ID for prod public frontend in eu-west-1"
}

variable "prod-public-frontend-peer-owner-id-euwest1" {
  description = "Peer Owner ID for prod public frontend in eu-west-1"
}

variable "prod-public-frontend-peer-region-eucentral1" {
  description = "Region of peer accepter in eu-central-1"
}

resource "aws_vpc_peering_connection" "prod-public-frontend-vpc-peer-requester-euwest1" {
  peer_vpc_id   = var.prod-private-frontend-peer-vpc-id-eucentral1
  vpc_id        = var.prod-public-frontend-vpc-id-euwest1
  peer_owner_id = var.prod-public-frontend-peer-owner-id-euwest1
  peer_region   = var.prod-public-frontend-peer-region-eucentral1
  auto_accept   = false

  tags = {
    Name = "prod-public-frontend-vpc-peer-requester-euwest1"
  }
}

output "prod-public-frontend-vpc-peer-conn-id-euwest1" {
  value = aws_vpc_peering_connection.prod-public-frontend-vpc-peer-requester-euwest1.id
}

resource "aws_vpc_peering_connection_options" "prod-public-frontend-vpc-peer-conn-opts-requester-euwest1" {
  vpc_peering_connection_id = aws_vpc_peering_connection.prod-public-frontend-vpc-peer-requester-euwest1.id
}

variable "prod-public-frontend-rt-id-euwest1" {
  description = "Route table ID in eu-west-1 of prod public frontend"
}

variable "CIDR-prod-private-backend-vpc-eucentral1" {
  description = "CIDR of VPC in prod private backend eu-central-1"
}

resource "aws_route" "prod-public-frontend-route-private-backend-vpc-peer-euwest1" {
  route_table_id = var.prod-public-frontend-rt-id-euwest1
  destination_cidr_block = var.CIDR-prod-private-backend-vpc-eucentral1
  vpc_peering_connection_id = aws_vpc_peering_connection.prod-public-frontend-vpc-peer-requester-euwest1.id

  depends_on = [aws_vpc_peering_connection.prod-public-frontend-vpc-peer-requester-euwest1]
}