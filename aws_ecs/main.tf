variable "AWS_EUWEST1_ACCESS_KEY" {
  description = "Access Key for AWS account in eu-west-1"
}

variable "AWS_EUWEST1_SECRET_KEY" {
  description = "Secret Key for AWS account in eu-west-1"
}

variable "MONGODB_USER" {
  description = "Username for MongoDB to init with and the API to authenticate with"
}

variable "MONGODB_PASSWORD" {
  description = "Password for MongoDB to init with and the API to authenticate with"
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 6.11.0"
    }
  }
}

data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
}

provider "aws" {
  region = "eu-west-1"
  access_key = var.AWS_EUWEST1_ACCESS_KEY
  secret_key = var.AWS_EUWEST1_SECRET_KEY
}

module "lab" {
  source = "./lab/"
  CIDR-prod-subnet-euwest1 = "10.0.0.0/24"
  CIDR-prod-vpc-euwest1 = "10.0.0.0/16"
  ACCOUNT = local.account_id
  REGION = "eu-west-1"
  AWS_EUWEST1_ACCESS_KEY = var.AWS_EUWEST1_ACCESS_KEY
  AWS_EUWEST1_SECRET_KEY = var.AWS_EUWEST1_SECRET_KEY
  CIDR-prod-subnet-az2-euwest1 = "10.0.1.0/24"
  prod-mongo-port-euwest1 = 27017
  CIDR-prod-subnet-az3-euwest1 = "10.0.2.0/24"
  MONGODB_PASSWORD = var.MONGODB_PASSWORD
  MONGODB_USER = var.MONGODB_USER
  prod-frontend-port-euwest1 = 80
}

output "prod-frontend-lb-euwest1-dns_name" {
  value = module.lab.prod-frontend-lb-euwest1-dns_name
}