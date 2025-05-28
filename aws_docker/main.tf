variable "AWS_EUWEST1_ACCESS_KEY" {
  description = "AWS Access Key in eu-west-1. Set with environment variable TF_VAR_AWS_ACCESS_KEY"
}

variable "AWS_EUWEST1_SECRET_KEY" {
  description = "AWS Secret Key in eu-west-1. Set with environment variable TF_VAR_AWS_SECRET_KEY"
}

provider "aws" {
  region = "eu-west-1"
  alias = "eu-west-1"
  access_key = var.AWS_EUWEST1_ACCESS_KEY
  secret_key = var.AWS_EUWEST1_SECRET_KEY
}

module "gw_docker" {
  source = "./gw_docker/"

  providers = {
    aws = aws.eu-west-1
  }

  allow_egress_cidr              = "0.0.0.0/0"
  allow_egress_protocol          = "-1"
  allow_ingress-http_cidr        = "0.0.0.0/0"
  allow_ingress-http_from_port   = 80
  allow_ingress-http_protocol    = "tcp"
  allow_ingress-http_to_port     = 80
  cidr_subnet-vpc-euwest1        = "10.0.1.0/24"
  cidr_subnet-vpc-euwest1-az     = "eu-west-1a"
  cidr_vpc-euwest1               = "10.0.0.0/16"
  eip_private_ip                 = "10.0.1.50"
  allow_ingress-ssh_cidr         = "0.0.0.0/0"
  allow_ingress-ssh_from_port    = 22
  allow_ingress-ssh_protocol     = "tcp"
  allow_ingress-ssh_to_port      = 22
  prod-euwest-1-route-table-cidr = "0.0.0.0/0"
  AWS_EUWEST1_ACCESS_KEY         = var.AWS_EUWEST1_ACCESS_KEY
  AWS_EUWEST1_SECRET_KEY         = var.AWS_EUWEST1_SECRET_KEY
}

output "ec2_instance_public_ip" {
  value = module.gw_docker.ec2_instance_public_ip
}

variable "AWS_USEAST1_ACCESS_KEY" {
  description = "AWS Access Key in us-east-1. Set with environment variable TF_VAR_AWS_USEAST1_ACCESS_KEY"
}

variable "AWS_USEAST1_SECRET_KEY" {
  description = "AWS Secret Key in us-east-1. Set with environment variable TF_VAR_AWS_USEAST1_SECRET_KEY"
}

provider "aws" {
  region = "us-east-1"
  alias = "us-east-1"
  access_key = var.AWS_USEAST1_ACCESS_KEY
  secret_key = var.AWS_USEAST1_SECRET_KEY
}

module "dynamodb" {
  source = "./dynamodb/"

  providers = {
    aws = aws.us-east-1
  }
}
