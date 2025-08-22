variable "AWS_EUWEST1_ACCESS_KEY" {
  description = "AWS Access Key in eu-west-1"
}

variable "AWS_EUWEST1_SECRET_KEY" {
  description = "AWS Secret Key in eu-west-1"
}

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

provider "aws" {
  region = "eu-west-1"
  access_key = var.AWS_EUWEST1_ACCESS_KEY
  secret_key = var.AWS_EUWEST1_SECRET_KEY
}

module "vpc" {
  source = "./vpc"

  CIDR-prod-backend-private-subnet-a2-euwest1        = "10.0.10.0/24"
  CIDR-prod-backend-private-subnet-b2-euwest1        = "10.0.20.0/24"
  CIDR-prod-frontend-public-subnet-a1-euwest1        = "10.0.1.0/24"
  CIDR-prod-frontend-public-subnet-b1-euwest1        = "10.0.2.0/24"
  CIDR-prod-route-igw-euwest1                        = "0.0.0.0/0"
  CIDR-prod-vpc-euwest1                              = "10.0.0.0/16"
  MONGODB_PASSWORD                                   = var.MONGODB_PASSWORD
  MONGODB_USER                                       = var.MONGODB_USER
  port-ingress-http-prod-frontend-public-a1-euwest1  = 80
  port-ingress-mongo-prod-backend-private-a2-euwest1 = 27017
  port-ingress-ssh-prod-frontend-public-a1-euwest1   = 22
}

output "alb_fqdn" {
  value = module.alb.alb_fqdn
}

module "alb" {
  source = "./alb"
  depends_on = [module.vpc]

  CIDR-prod-route-igw-euwest1                       = "0.0.0.0/0"
  port-ingress-http-prod-frontend-public-a1-euwest1 = 80
  prod-frontend-public-a1-ec2-instance-euwest1      = module.vpc.prod-frontend-public-a1-ec2-instance-euwest1
  prod-frontend-public-a1-ec2-instance-euwest1-id   = module.vpc.prod-frontend-public-a1-ec2-instance-euwest1-id
  prod-frontend-public-b1-ec2-instance-euwest1      = module.vpc.prod-frontend-public-b1-ec2-instance-euwest1
  prod-frontend-public-b1-ec2-instance-euwest1-id   = module.vpc.prod-frontend-public-b1-ec2-instance-euwest1-id
  prod-frontend-public-subnet-a1-euwest1-id         = module.vpc.prod-frontend-public-subnet-a1-euwest1-id
  prod-frontend-public-subnet-b1-euwest1-id         = module.vpc.prod-frontend-public-subnet-b1-euwest1-id
  prod-vpc-euwest1-id                               = module.vpc.prod-vpc-euwest1-id
}