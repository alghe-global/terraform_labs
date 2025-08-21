terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 6.9.0"
    }
  }
}

variable "prod-public-frontend-vpc-peer-conn-id-euwest1" {
  description = "VPC Peering Connection ID of prod public frontend in eu-west-1"
}

resource "aws_vpc_peering_connection_accepter" "prod-private-backend-vpc-peer-conn-accepter-eucentral1" {
  vpc_peering_connection_id = var.prod-public-frontend-vpc-peer-conn-id-euwest1
  auto_accept = true
}

resource "aws_vpc_peering_connection_options" "prod-private-backend-vpc-peer-conn-opts-accepter-eucentral1" {
  vpc_peering_connection_id = var.prod-public-frontend-vpc-peer-conn-id-euwest1
}

variable "prod-private-backend-rt-id-eucentral1" {
  description = "Route table ID in eu-central-1 of prod private backend"
}

variable "CIDR-prod-public-frontend-vpc-euwest1" {
  description = "CIDR of VPC in prod public frontend eu-west-1"
}

resource "aws_route" "prod-private-backend-route-public-frontend-vpc-peer-eucentral1" {
  route_table_id = var.prod-private-backend-rt-id-eucentral1
  destination_cidr_block = var.CIDR-prod-public-frontend-vpc-euwest1
  vpc_peering_connection_id = var.prod-public-frontend-vpc-peer-conn-id-euwest1
}