terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 6.11.0"
    }
  }
}

variable "CIDR-prod-vpc-euwest1" {
  description = "CIDR for prod VPC in eu-west-1"
}

resource "aws_vpc" "prod-vpc-euwest1" {
  cidr_block = var.CIDR-prod-vpc-euwest1

  tags = {
    Name = "prod-vpc-euwest1"
  }
}

resource "aws_internet_gateway" "prod-vpc-igw-euwest1" {
  vpc_id = aws_vpc.prod-vpc-euwest1.id

  tags = {
    Name = "prod-vpc-igw-euwest1"
  }
}

variable "CIDR-prod-subnet-euwest1" {
  description = "CIDR for prod subnet in eu-west-1"
}

resource "aws_subnet" "prod-subnet-euwest1" {
  vpc_id = aws_vpc.prod-vpc-euwest1.id
  cidr_block = var.CIDR-prod-subnet-euwest1
  availability_zone = "eu-west-1a"

  tags = {
    Name = "prod-subnet-euwest1"
  }
}

resource "aws_route_table" "prod-rt-euwest1" {
  vpc_id = aws_vpc.prod-vpc-euwest1.id
}

resource "aws_route" "prod-rt-igw-euwest1" {
  route_table_id = aws_route_table.prod-rt-euwest1.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.prod-vpc-igw-euwest1.id
}

resource "aws_route_table_association" "prod-rt-igw-assoc-euwest1" {
  route_table_id = aws_route_table.prod-rt-euwest1.id
  subnet_id = aws_subnet.prod-subnet-euwest1.id
}

resource "aws_ecr_repository" "prod-ecr-euwest1" {
  name = "prod-ecr-euwest1"
  image_tag_mutability = "IMMUTABLE"

  tags = {
    Name = "prod-ecr-euwest1"
  }
}

data "aws_iam_policy_document" "prod-ec2-iam-role-policy-document-euwest1" {
  statement {
    sid = "all"
    actions = [
      "ec2:TerminateInstances"
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_role_policy" "prod-ec2-iam-role-policy-euwest1" {
  role       = aws_iam_role.prod-ec2-iam-role-euwest1.name
  policy     = data.aws_iam_policy_document.prod-ec2-iam-role-policy-document-euwest1.json
}

resource "aws_iam_role" "prod-ec2-iam-role-euwest1" {
  name = "prod-ec2-iam-role-euwest1"
  assume_role_policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Action = "sts:AssumeRole"
          Effect = "Allow"
          Sid    = ""
          Principal = {
            Service = "ec2.amazonaws.com"
          }
        },
      ]
    }
  )

  tags = {
    Name = "prod-ec2-iam-role-euwest1"
  }
}

resource "aws_iam_instance_profile" "prod-ec2-instance-profile-euwest1" {
  name = "prod-ec2-instance-profile-euwest1"
  role = aws_iam_role.prod-ec2-iam-role-euwest1.name
}

# This SG allows all traffic inbound and outbound and is used for both independent EC2 instance and ELBs
# WARNING: DO NOT USE such configuration in production!
resource "aws_security_group" "prod-ec2-sg-euwest1" {
  name = "prod-ec2-sg-euwest1"
  description = "EC2 Security Group for instance in eu-west-1"
  vpc_id = aws_vpc.prod-vpc-euwest1.id

  tags = {
    Name = "prod-ec2-sg-euwest1"
  }
}

resource "aws_vpc_security_group_ingress_rule" "prod-ec2-sg-ingress-euwest1" {
  cidr_ipv4 = "0.0.0.0/0"
  from_port = -1
  ip_protocol       = "-1"
  security_group_id = aws_security_group.prod-ec2-sg-euwest1.id
  to_port = -1
}

resource "aws_vpc_security_group_egress_rule" "prod-ec2-sg-egress-euwest1" {
  cidr_ipv4 = "0.0.0.0/0"
  from_port = -1
  ip_protocol       = "-1"
  security_group_id = aws_security_group.prod-ec2-sg-euwest1.id
  to_port = -1
}

variable "REGION" {
  description = "The region in which the ECR repo was created"
}

variable "ACCOUNT" {
  description = "The account ID with which the ECR repo was created"
}

variable "AWS_EUWEST1_ACCESS_KEY" {
  description = "Access Key for AWS account in eu-west-1"
}

variable "AWS_EUWEST1_SECRET_KEY" {
  description = "Secret Key for AWS account in eu-west-1"
}

# Create EC2 instance in order to push public docker image to private ECR
resource "aws_instance" "prod-ec2-instance-euwest1" {
  ami = "ami-0bc691261a82b32bc"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.prod-subnet-euwest1.id
  associate_public_ip_address = true
  key_name = "lab"
  security_groups = [aws_security_group.prod-ec2-sg-euwest1.id]
  depends_on = [aws_internet_gateway.prod-vpc-igw-euwest1, aws_ecr_repository.prod-ecr-euwest1]

  user_data = <<-EOF
#!/bin/bash
sudo apt update

# Install git
sudo apt install -y git

# Add Docker's official GPG key:
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  ${"$"}(. /etc/os-release && echo "${"$"}{UBUNTU_CODENAME:-${"$"}VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

# Install Docker
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Clone repository and change directory to Docker image directory
su ubuntu -c 'cd /home/ubuntu && \
    git clone https://github.com/alghe-global/terraform_labs.git'

# Docker boilerplate
sudo groupadd docker
sudo usermod -aG docker ubuntu
sudo newgrp docker

# Build image for ECR
su ubuntu -c 'cd /home/ubuntu/terraform_labs/aws_vpc/docker/public && \
    docker build -t ${aws_ecr_repository.prod-ecr-euwest1.repository_url} .'

# Login and push to ECR
sudo snap install aws-cli --classic
su ubuntu -c 'echo -e "${var.AWS_EUWEST1_ACCESS_KEY}\n${var.AWS_EUWEST1_SECRET_KEY}\n${var.REGION}\n" | aws configure'

su ubuntu -c 'aws ecr get-login-password \
    --region ${var.REGION} \
| docker login \
    --username AWS \
    --password-stdin ${var.ACCOUNT}.dkr.ecr.${var.REGION}.amazonaws.com'

su ubuntu -c 'docker push ${aws_ecr_repository.prod-ecr-euwest1.repository_url}'

# Terminate the instance as it has fulfilled its role
su ubuntu -c 'aws ec2 terminate-instances \
    --instance-ids $(curl http://169.254.169.254/latest/meta-data/instance-id) \
    --region $(curl http://169.254.169.254/latest/meta-data/placement/region)'
EOF

  tags = {
    Name = "prod-ec2-instance-euwest1"
  }
}

# Create ECS
resource "aws_ecs_cluster" "prod-ecs-cluster-euwest1" {
  name = "prod-ecs-cluster-euwest1"

  tags = {
    Name = "prod-ecs-cluster-euwest1"
  }
}

resource "aws_iam_role_policy" "prod-ecs-iam-role-policy-euwest1" {
  role   = aws_iam_role.prod-ecs-iam-role-euwest1.name

  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "ECSTaskManagement",
            "Effect": "Allow",
            "Action": [
                "ec2:AttachNetworkInterface",
                "ec2:CreateNetworkInterface",
                "ec2:CreateNetworkInterfacePermission",
                "ec2:DeleteNetworkInterface",
                "ec2:DeleteNetworkInterfacePermission",
                "ec2:Describe*",
                "ec2:DetachNetworkInterface",
                "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
                "elasticloadbalancing:DeregisterTargets",
                "elasticloadbalancing:Describe*",
                "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
                "elasticloadbalancing:RegisterTargets",
                "route53:ChangeResourceRecordSets",
                "route53:CreateHealthCheck",
                "route53:DeleteHealthCheck",
                "route53:Get*",
                "route53:List*",
                "route53:UpdateHealthCheck",
                "servicediscovery:DeregisterInstance",
                "servicediscovery:Get*",
                "servicediscovery:List*",
                "servicediscovery:RegisterInstance",
                "servicediscovery:UpdateInstanceCustomHealthStatus"
            ],
            "Resource": "*"
        },
        {
            "Sid": "AutoScaling",
            "Effect": "Allow",
            "Action": [
                "autoscaling:Describe*"
            ],
            "Resource": "*"
        },
        {
            "Sid": "AutoScalingManagement",
            "Effect": "Allow",
            "Action": [
                "autoscaling:DeletePolicy",
                "autoscaling:PutScalingPolicy",
                "autoscaling:SetInstanceProtection",
                "autoscaling:UpdateAutoScalingGroup",
                "autoscaling:PutLifecycleHook",
                "autoscaling:DeleteLifecycleHook",
                "autoscaling:CompleteLifecycleAction",
                "autoscaling:RecordLifecycleActionHeartbeat"
            ],
            "Resource": "*",
            "Condition": {
                "Null": {
                    "autoscaling:ResourceTag/AmazonECSManaged": "false"
                }
            }
        },
        {
            "Sid": "AutoScalingPlanManagement",
            "Effect": "Allow",
            "Action": [
                "autoscaling-plans:CreateScalingPlan",
                "autoscaling-plans:DeleteScalingPlan",
                "autoscaling-plans:DescribeScalingPlans",
                "autoscaling-plans:DescribeScalingPlanResources"
            ],
            "Resource": "*"
        },
        {
            "Sid": "EventBridge",
            "Effect": "Allow",
            "Action": [
                "events:DescribeRule",
                "events:ListTargetsByRule"
            ],
            "Resource": "arn:aws:events:*:*:rule/ecs-managed-*"
        },
        {
            "Sid": "EventBridgeRuleManagement",
            "Effect": "Allow",
            "Action": [
                "events:PutRule",
                "events:PutTargets"
            ],
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "events:ManagedBy": "ecs.amazonaws.com"
                }
            }
        },
        {
            "Sid": "CWAlarmManagement",
            "Effect": "Allow",
            "Action": [
                "cloudwatch:DeleteAlarms",
                "cloudwatch:DescribeAlarms",
                "cloudwatch:PutMetricAlarm"
            ],
            "Resource": "arn:aws:cloudwatch:*:*:alarm:*"
        },
        {
            "Sid": "ECSTagging",
            "Effect": "Allow",
            "Action": [
                "ec2:CreateTags"
            ],
            "Resource": "arn:aws:ec2:*:*:network-interface/*"
        },
        {
            "Sid": "CWLogGroupManagement",
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:DescribeLogGroups",
                "logs:PutRetentionPolicy"
            ],
            "Resource": "arn:aws:logs:*:*:log-group:/aws/ecs/*"
        },
        {
            "Sid": "CWLogStreamManagement",
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:DescribeLogStreams",
                "logs:PutLogEvents"
            ],
            "Resource": "arn:aws:logs:*:*:log-group:/aws/ecs/*:log-stream:*"
        },
        {
            "Sid": "ExecuteCommandSessionManagement",
            "Effect": "Allow",
            "Action": [
                "ssm:DescribeSessions"
            ],
            "Resource": "*"
        },
        {
            "Sid": "ExecuteCommand",
            "Effect": "Allow",
            "Action": [
                "ssm:StartSession"
            ],
            "Resource": [
                "arn:aws:ecs:*:*:task/*",
                "arn:aws:ssm:*:*:document/AmazonECS-ExecuteInteractiveCommand"
            ]
        },
        {
            "Sid": "CloudMapResourceCreation",
            "Effect": "Allow",
            "Action": [
                "servicediscovery:CreateHttpNamespace",
                "servicediscovery:CreateService"
            ],
            "Resource": "*",
            "Condition": {
                "ForAllValues:StringEquals": {
                    "aws:TagKeys": [
                        "AmazonECSManaged"
                    ]
                }
            }
        },
        {
            "Sid": "CloudMapResourceTagging",
            "Effect": "Allow",
            "Action": "servicediscovery:TagResource",
            "Resource": "*",
            "Condition": {
                "StringLike": {
                    "aws:RequestTag/AmazonECSManaged": "*"
                }
            }
        },
        {
            "Sid": "CloudMapResourceDeletion",
            "Effect": "Allow",
            "Action": [
                "servicediscovery:DeleteService"
            ],
            "Resource": "*",
            "Condition": {
                "Null": {
                    "aws:ResourceTag/AmazonECSManaged": "false"
                }
            }
        },
        {
            "Sid": "CloudMapResourceDiscovery",
            "Effect": "Allow",
            "Action": [
                "servicediscovery:DiscoverInstances",
                "servicediscovery:DiscoverInstancesRevision"
            ],
            "Resource": "*"
        },
        {
            "Sid": "CloudMapResourceAttributeManagement",
            "Effect": "Allow",
            "Action": [
                "servicediscovery:UpdateServiceAttributes"
            ],
            "Resource": "*",
            "Condition": {
                "Null": {
                    "aws:ResourceTag/AmazonECSManaged": "false"
                }
            }
        },
        {
            "Sid": "EcrGetAuthorizationToken",
            "Effect": "Allow",
            "Action": [
                "ecr:GetAuthorizationToken"
            ],
            "Resource": "*"
        },
        {
            "Sid": "AllowPushPull",
            "Effect": "Allow",
            "Resource": "*",
            "Action": [
                "ecr:BatchGetImage",
                "ecr:BatchCheckLayerAvailability",
                "ecr:CompleteLayerUpload",
                "ecr:GetDownloadUrlForLayer",
                "ecr:InitiateLayerUpload",
                "ecr:PutImage",
                "ecr:UploadLayerPart"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_role" "prod-ecs-iam-role-euwest1" {
  name = "prod-ecs-iam-role-euwest1"
  assume_role_policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Action = "sts:AssumeRole"
          Effect = "Allow"
          Sid    = ""
          Principal = {
            Service = [
              "ecs.amazonaws.com",
              "ecs-tasks.amazonaws.com"
            ]
          }
        },
      ]
    }
  )

  tags = {
    Name = "prod-ecs-iam-role-euwest1"
  }
}

variable "prod-mongo-port-euwest1" {
  description = "Port Mongo DB is listening on"
}

variable "MONGODB_USER" {
  description = "Username for MongoDB to init with and the API to authenticate with"
}

variable "MONGODB_PASSWORD" {
  description = "Password for MongoDB to init with and the API to authenticate with"
}

resource "aws_ecs_task_definition" "prod-ecs-mongo-task-defn-euwest1" {
  family                = "prod-mongo"
  network_mode = "awsvpc"
  cpu = 512
  memory = 1024
  requires_compatibilities = ["FARGATE"]
  depends_on = [aws_lb.prod-mongo-lb-euwest1, aws_instance.prod-ec2-instance-euwest1]

  container_definitions = jsonencode(
    [
      {
        name = "mongo"
        image = "mongo"
        essential = true
        portMappings = [
          {
            containerPort = var.prod-mongo-port-euwest1
            hostPort = var.prod-mongo-port-euwest1
          }
        ]
        environment = [
          {
            name  = "MONGO_INITDB_ROOT_USERNAME"
            value = var.MONGODB_USER
          },
          {
            name = "MONGO_INITDB_ROOT_PASSWORD"
            value = var.MONGODB_PASSWORD
          }
        ]
      }
    ]
  )

  tags = {
    Name = "prod-ecs-mongo-task-defn-euwest1"
  }
}

resource "aws_lb_target_group" "prod-mongo-lb-group-euwest1" {
  name = "prod-mongo-lb-group-euwest1"
  port = var.prod-mongo-port-euwest1
  protocol = "TCP"
  target_type = "ip"
  vpc_id = aws_vpc.prod-vpc-euwest1.id

  health_check {
    port = var.prod-mongo-port-euwest1
    protocol = "TCP"
    timeout = 30  # XXX: we need to be relaxed here as there may be delay due to docker start-up
  }

  tags = {
    Name = "prod-mongo-lb-group-euwest1"
  }
}

resource "aws_ecs_service" "prod-mongo-ecs-service-euwest1" {
  name = "prod-mongo-ecs-service-euwest1"
  cluster = aws_ecs_cluster.prod-ecs-cluster-euwest1.id
  task_definition = aws_ecs_task_definition.prod-ecs-mongo-task-defn-euwest1.id
  desired_count = 2
  launch_type = "FARGATE"
  depends_on = [
    aws_ecs_task_definition.prod-ecs-mongo-task-defn-euwest1,
    aws_route_table_association.prod-rt-igw-assoc-euwest1,
    aws_route_table_association.prod-rt-igw-assoc-subnet-az2-euwest1,
    aws_route_table_association.prod-rt-igw-assoc-subnet-az3-euwest1
  ]

  load_balancer {
    target_group_arn = aws_lb_target_group.prod-mongo-lb-group-euwest1.arn
    container_name = "mongo"
    container_port = var.prod-mongo-port-euwest1
  }

  network_configuration {
    # WARNING: DO NOT assign a public IP in production
    assign_public_ip = true
    security_groups = [aws_security_group.prod-ec2-sg-euwest1.id]
    subnets = [
      aws_subnet.prod-subnet-euwest1.id,
      aws_subnet.prod-subnet-az2-euwest1.id,
      aws_subnet.prod-subnet-az3-euwest1.id
    ]
  }

  tags = {
    Name = "prod-mongo-ecs-service-euwest1"
  }
}

variable "CIDR-prod-subnet-az2-euwest1" {
  description = "CIDR for prod subnet in second AZ in eu-west-1"
}

resource "aws_subnet" "prod-subnet-az2-euwest1" {
  cidr_block = var.CIDR-prod-subnet-az2-euwest1
  vpc_id = aws_vpc.prod-vpc-euwest1.id
  availability_zone = "eu-west-1b"

  tags = {
    Name = "prod-subnet-az2-euwest1"
  }
}

resource "aws_route_table_association" "prod-rt-igw-assoc-subnet-az2-euwest1" {
  route_table_id = aws_route_table.prod-rt-euwest1.id
  subnet_id = aws_subnet.prod-subnet-az2-euwest1.id
}

variable "CIDR-prod-subnet-az3-euwest1" {
  description = "CIDR for prod subnet in third AZ in eu-west-1"
}

resource "aws_subnet" "prod-subnet-az3-euwest1" {
  cidr_block = var.CIDR-prod-subnet-az3-euwest1
  vpc_id = aws_vpc.prod-vpc-euwest1.id
  availability_zone = "eu-west-1c"

  tags = {
    Name = "prod-subnet-az3-euwest1"
  }
}

resource "aws_route_table_association" "prod-rt-igw-assoc-subnet-az3-euwest1" {
  route_table_id = aws_route_table.prod-rt-euwest1.id
  subnet_id = aws_subnet.prod-subnet-az3-euwest1.id
}

resource "aws_lb" "prod-mongo-lb-euwest1" {
  name = "prod-mongo-lb-euwest1"
  load_balancer_type = "network"
  security_groups = [aws_security_group.prod-ec2-sg-euwest1.id]
  subnets = [
    aws_subnet.prod-subnet-euwest1.id,
    aws_subnet.prod-subnet-az2-euwest1.id,
    aws_subnet.prod-subnet-az3-euwest1.id
  ]
  depends_on = [aws_instance.prod-ec2-instance-euwest1, aws_lb_target_group.prod-mongo-lb-group-euwest1]

  tags = {
    Name = "prod-mongo-lb-euwest1"
  }
}

resource "aws_lb_listener" "prod-mongo-lb-listener-euwest1" {
  load_balancer_arn = aws_lb.prod-mongo-lb-euwest1.arn
  port = var.prod-mongo-port-euwest1
  protocol = "TCP"
  depends_on = [aws_lb_target_group.prod-mongo-lb-group-euwest1]

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.prod-mongo-lb-group-euwest1.arn
  }

  tags = {
    Name = "prod-mongo-lb-listener-euwest1"
  }
}

# Allow EC2 instance to have pushed the image to ECR repository so that frontend container creation is successful
resource "time_sleep" "wait_5_minutes" {
  create_duration = "5m"

  depends_on = [aws_instance.prod-ec2-instance-euwest1]
}

variable "prod-frontend-port-euwest1" {
  description = "Port frontend API is listening on"
}

resource "aws_ecs_task_definition" "prod-ecs-frontend-task-defn-euwest1" {
  family                = "prod-frontend"
  network_mode = "awsvpc"
  cpu = 512
  memory = 1024
  requires_compatibilities = ["FARGATE"]
  task_role_arn = aws_iam_role.prod-ecs-iam-role-euwest1.arn
  execution_role_arn = aws_iam_role.prod-ecs-iam-role-euwest1.arn
  depends_on = [
    time_sleep.wait_5_minutes,
    aws_lb.prod-frontend-lb-euwest1,
    aws_lb.prod-mongo-lb-euwest1,
    aws_instance.prod-ec2-instance-euwest1
  ]

  container_definitions = jsonencode(
    [
      {
        name = "frontend"
        image = aws_ecr_repository.prod-ecr-euwest1.repository_url
        essential = true
        portMappings = [
          {
            containerPort = var.prod-frontend-port-euwest1
            hostPort = var.prod-frontend-port-euwest1
          }
        ]
        environment = [
          {
            name  = "MONGODB_USER"
            value = var.MONGODB_USER
          },
          {
            name = "MONGODB_PASSWORD"
            value = var.MONGODB_PASSWORD
          },
          {
            name = "MONGODB_HOST"
            value = aws_lb.prod-mongo-lb-euwest1.dns_name
          }
        ]
      }
    ]
  )

  tags = {
    Name = "prod-ecs-frontend-task-defn-euwest1"
  }
}

resource "aws_lb_target_group" "prod-frontend-lb-group-euwest1" {
  name = "prod-frontend-lb-group-euwest1"
  port = var.prod-frontend-port-euwest1
  protocol = "HTTP"
  target_type = "ip"
  vpc_id = aws_vpc.prod-vpc-euwest1.id

  health_check {
    port = var.prod-frontend-port-euwest1
    protocol = "HTTP"
    timeout = 29  # XXX: we need to be relaxed here as there may be delay due to docker start-up
  }

  tags = {
    Name = "prod-frontend-lb-group-euwest1"
  }
}

resource "aws_ecs_service" "prod-frontend-ecs-service-euwest1" {
  name = "prod-frontend-ecs-service-euwest1"
  cluster = aws_ecs_cluster.prod-ecs-cluster-euwest1.id
  task_definition = aws_ecs_task_definition.prod-ecs-frontend-task-defn-euwest1.id
  desired_count = 2
  launch_type = "FARGATE"
  depends_on = [
    aws_ecs_task_definition.prod-ecs-frontend-task-defn-euwest1,
    aws_route_table_association.prod-rt-igw-assoc-euwest1,
    aws_route_table_association.prod-rt-igw-assoc-subnet-az2-euwest1,
    aws_route_table_association.prod-rt-igw-assoc-subnet-az3-euwest1
  ]

  load_balancer {
    target_group_arn = aws_lb_target_group.prod-frontend-lb-group-euwest1.arn
    container_name = "frontend"
    container_port = var.prod-frontend-port-euwest1
  }

  network_configuration {
    # WARNING: DO NOT assign a public IP in production
    assign_public_ip = true
    security_groups = [aws_security_group.prod-ec2-sg-euwest1.id]
    subnets = [
      aws_subnet.prod-subnet-euwest1.id,
      aws_subnet.prod-subnet-az2-euwest1.id,
      aws_subnet.prod-subnet-az3-euwest1.id
    ]
  }

  tags = {
    Name = "prod-frontend-ecs-service-euwest1"
  }
}

resource "aws_lb" "prod-frontend-lb-euwest1" {
  name = "prod-frontend-lb-euwest1"
  security_groups = [aws_security_group.prod-ec2-sg-euwest1.id]
  subnets = [
    aws_subnet.prod-subnet-euwest1.id,
    aws_subnet.prod-subnet-az2-euwest1.id,
    aws_subnet.prod-subnet-az3-euwest1.id
  ]
  depends_on = [aws_instance.prod-ec2-instance-euwest1, aws_lb_target_group.prod-frontend-lb-group-euwest1]

  tags = {
    Name = "prod-frontend-lb-euwest1"
  }
}

output "prod-frontend-lb-euwest1-dns_name" {
  value = aws_lb.prod-frontend-lb-euwest1.dns_name
}

resource "aws_lb_listener" "prod-frontend-lb-group-euwest1" {
  load_balancer_arn = aws_lb.prod-frontend-lb-euwest1.arn
  port = var.prod-frontend-port-euwest1
  protocol = "HTTP"
  depends_on = [aws_lb_target_group.prod-frontend-lb-group-euwest1]

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.prod-frontend-lb-group-euwest1.arn
  }

  tags = {
    Name = "prod-frontend-lb-group-euwest1"
  }
}