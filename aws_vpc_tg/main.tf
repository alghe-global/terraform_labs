variable "AWS_EUWEST1_ACCESS_KEY" {
  description = "Access Key for account in eu-west-1"
}

variable "AWS_EUWEST1_SECRET_KEY" {
  description = "Secret Key for account in eu-west-1"
}

variable "MONGODB_USER" {
  description = "MongoDB user to use for setting up the backend and for frontend to know which user to use"
}

variable "MONGODB_PASSWORD" {
  description = "MongoDB password to use for setting up the backend and for the frontend to know which password to use"
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

  CIDR-egress-prod-public-backend                      = "0.0.0.0/0"
  CIDR-ingress-prod-public-backend                     = "10.1.0.150/32"
  CIDR-prod-public-backend-subnet                      = "10.2.0.0/24"
  CIDR-prod-public-backend-vpc                         = "10.2.0.0/16"
  CIDR-prod-public-frontend-subnet                     = "10.1.0.0/24"
  CIDR-prod-public-frontend-vpc                        = "10.1.0.0/16"
  MONGODB_PASSWORD                                     = var.MONGODB_PASSWORD
  MONGODB_USER                                         = var.MONGODB_USER
  egress-cidr-public-frontend                          = "0.0.0.0/0"
  egress-from-to-port-public-backend                   = "0"
  egress-from-to-port-public-frontend                  = "0"
  ingress-http-from-to-port-prod-public-frontend       = "80"
  ingress-http-ssh-cidr-prod-public-frontend           = "0.0.0.0/0"
  ingress-mongo-from-to-port-prod-public-backend       = "27017"
  ingress-ssh-from-to-port-prod-public-frontend        = "22"
  prod-public-frontend-ec2-instance-euwest1-private-ip = "10.1.0.150"
  prod-public-backend-ec2-instance-euwest1-private-ip  = "10.2.0.15"
}

module "tg" {
  source = "./tg"
  depends_on = [module.vpc]

  CIDR-prod-public-backend-vpc     = "10.2.0.0/16"
  CIDR-prod-public-frontend-vpc    = "10.1.0.0/16"
  prod-backend-subnet-id-euwest1   = module.vpc.prod-backend-subnet-id-euwest1
  prod-backend-vpc-id-euwest1      = module.vpc.prod-backend-vpc-id-euwest1
  prod-frontend-subnet-id-euwest1  = module.vpc.prod-frontend-subnet-id-euwest1
  prod-frontend-vpc-id-euwest1     = module.vpc.prod-frontend-vpc-id-euwest1
  prod-public-backend-rt-id        = module.vpc.prod-public-backend-rt-id
  prod-public-frontend-rt-id       = module.vpc.prod-public-frontend-rt-id
}