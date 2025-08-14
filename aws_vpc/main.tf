variable "AWS_EUWEST1_ACCESS_KEY" {
  description = "AWS Access Key in eu-west-1. Set with environment variable TF_VAR_AWS_EUWEST1_ACCESS_KEY"
}

variable "AWS_EUWEST1_SECRET_KEY" {
  description = "AWS Secret Key in eu-west-1. Set with environment variable TF_VAR_AWS_EUWEST1_SECRET_KEY"
}

variable "MONGODB_USER" {
  description = "Username for MongoDB to init with and the API to authenticate with"
}

variable "MONGODB_PASSWORD" {
  description = "Password for MongoDB To init with and the API to authenticate with"
}

provider "aws" {
  region = "eu-west-1"
  alias = "eu-west-1"
  access_key = var.AWS_EUWEST1_ACCESS_KEY
  secret_key = var.AWS_EUWEST1_SECRET_KEY
}

module "euwest1" {
  source = "./euwest1/"

  providers = {
    aws = aws.eu-west-1
  }

  cidr-prod-vpc-euwest1 = "10.0.0.0/16"
  cidr-prod-public-subnet-euwest1 = "10.0.0.0/24"
  az-prod-public-subnet-euwest1 = "eu-west-1a"
  cidr-prod-private-subnet-euwest1 = "10.0.1.0/24"
  az-prod-private-subnet-euwest1 = "eu-west-1b"
  cidr-all-route-table-prod-nat-gw-euwest1 = "0.0.0.0/0"
  MONGODB_USER = var.MONGODB_USER
  MONGODB_PASSWORD = var.MONGODB_PASSWORD
  cidr-prod-public-ec2-instance-sg-rule-ingress-ssh-http-euwest1 = "0.0.0.0/0"
  port-prod-public-ec2-instance-sg-rule-ingress-ssh-euwest1 = 22
  port-prod-public-ec2-instance-sg-rule-ingress-http-euwest1 = 80
  cidr-prod-public-ec2-instance-sg-rule-egress-ssh-euwest1 = "0.0.0.0/0"
  prod-private-ec2-instance-euwest1-private-ip = "10.0.1.50"
  port-prod-private-ec2-instance-sg-rule-ingress-mongo-euwest1 = 27017
}

output "nat_public_eip" {
  value = module.euwest1.prod-public-nat-gw-eip-euwest1
}

output "public_ec2_instance_eip" {
  value = module.euwest1.prod-public-ec2-instance-eip-euwest1
}