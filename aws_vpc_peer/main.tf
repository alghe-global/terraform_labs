variable "AWS_EUWEST1_ACCESS_KEY" {
  description = "AWS Access Key for eu-west-1"
}

variable "AWS_EUWEST1_SECRET_KEY" {
  description = "AWS Secret Key for eu-west-1"
}

variable "MONGODB_USER" {
  description = "MongoDB user to use for setting up backend as well as frontend"
}

variable "MONGODB_PASSWORD" {
  description = "MongoDB password to use for setting up backend as well as frontend"
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
  alias  = "eu-west-1"
  access_key = var.AWS_EUWEST1_ACCESS_KEY
  secret_key = var.AWS_EUWEST1_SECRET_KEY
}

module "vpc-euwest1" {
  source = "./vpc/euwest1"

  providers = {
    aws = aws.eu-west-1
  }

  CIDR-prod-public-frontend-route-euwest1                 = "0.0.0.0/0"
  CIDR-prod-public-frontend-subnet-euwest1                = "10.1.0.0/24"
  CIDR-prod-public-frontend-vpc-euwest1                   = "10.1.0.0/16"
  MONGODB_PASSWORD                                        = var.MONGODB_PASSWORD
  MONGODB_USER                                            = var.MONGODB_USER
  prod-private-backend-ec2-instance-eucentral1-private-ip = "10.2.0.15"
  prod-public-frontend-ec2-instance-euwest1-private-ip    = "10.1.0.150"
  prod-public-frontend-ssh-port-sg-rule-euwest1           = 22
  prod-public-frontend-http-port-sg-rule-euwest1          = 80
}

provider "aws" {
  region = "eu-central-1"
  alias  = "eu-central-1"
  access_key = var.AWS_EUWEST1_ACCESS_KEY
  secret_key = var.AWS_EUWEST1_SECRET_KEY
}

module "vpc-eucentral1" {
  source = "./vpc/eucentral1"

  providers = {
    aws = aws.eu-central-1
  }

  CIDR-prod-private-backend-subnet-eucentral1             = "10.2.0.0/24"
  CIDR-prod-private-backend-vpc-eucentral1                = "10.2.0.0/16"
  CIDR-prod-public-backend-route-ngw-eucentral1           = "0.0.0.0/0"
  CIDR-prod-public-backend-subnet-eucentral1              = "10.2.1.0/24"
  MONGODB_PASSWORD                                        = var.MONGODB_PASSWORD
  MONGODB_USER                                            = var.MONGODB_USER
  prod-private-backend-ec2-instance-eucentral1-private-ip = "10.2.0.15"
  prod-private-backend-ssh-port-sg-rule-eucentral1        = 22
  prod-public-backend-mongo-port-sg-rule-eucentral1       = 27017
  prod-public-frontend-ec2-instance-euwest1-private-ip    = "10.1.0.150"
}

data "aws_caller_identity" "peer-euwest1" {
  provider = aws.eu-west-1
}

module "peer-euwest1" {
  source = "./peer-euwest1"
  depends_on = [module.vpc-euwest1, module.vpc-eucentral1]

  providers = {
    aws = aws.eu-west-1
  }

  prod-public-frontend-peer-owner-id-euwest1     = data.aws_caller_identity.peer-euwest1.account_id
  prod-private-frontend-peer-vpc-id-eucentral1   = module.vpc-eucentral1.prod-private-frontend-peer-vpc-id-eucentral1
  prod-public-frontend-vpc-id-euwest1            = module.vpc-euwest1.prod-public-frontend-vpc-id-euwest1
  CIDR-prod-private-backend-vpc-eucentral1       = "10.2.0.0/16"
  prod-public-frontend-rt-id-euwest1             = module.vpc-euwest1.prod-public-frontend-rt-id-euwest1
  prod-public-frontend-peer-region-eucentral1    = "eu-central-1"
}

module "peer-eucentral1" {
  source = "./peer-eucentral1"
  depends_on = [module.vpc-euwest1, module.vpc-eucentral1]

  providers = {
    aws = aws.eu-central-1
  }

  prod-public-frontend-vpc-peer-conn-id-euwest1 = module.peer-euwest1.prod-public-frontend-vpc-peer-conn-id-euwest1
  CIDR-prod-public-frontend-vpc-euwest1         = "10.1.0.0/16"
  prod-private-backend-rt-id-eucentral1         = module.vpc-eucentral1.prod-private-backend-rt-id-eucentral1
}