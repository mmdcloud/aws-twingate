# -----------------------------------------------------------------------------------------
# Data Sources
# -----------------------------------------------------------------------------------------
data "aws_elb_service_account" "elb_service_account" {}

data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"]
}

data "aws_ami" "twingate" {
  most_recent = true
  filter {
    name   = "name"
    values = ["twingate/images/hvm-ssd/twingate-amd64-*"]
  }
  owners = ["617935088040"]
}

data "aws_key_pair" "key_pair" {
  key_name = var.key_pair_name
}

data "twingate_users" "lookup" {
  email = var.existing_user_email
}

# -----------------------------------------------------------------------------------------
# Locals
# -----------------------------------------------------------------------------------------
locals {
  existing_user_id = data.twingate_users.lookup.users[0].id
}

# -----------------------------------------------------------------------------------------
# Creating random id configuration
# -----------------------------------------------------------------------------------------
resource "random_id" "id" {
  byte_length = 8
}

# -----------------------------------------------------------------------------------------
# VPC Configuration
# -----------------------------------------------------------------------------------------
module "twingate_vpc" {
  source                  = "./modules/vpc"
  vpc_name                = var.vpc_name
  vpc_cidr                = var.vpc_cidr
  azs                     = var.azs
  public_subnets          = var.public_subnets
  private_subnets         = var.private_subnets
  enable_dns_hostnames    = true
  enable_dns_support      = true
  create_igw              = true
  map_public_ip_on_launch = true
  enable_nat_gateway      = true
  single_nat_gateway      = false
  one_nat_gateway_per_az  = true
  tags = {
    Name = var.vpc_name
  }
}

# Security Group
module "twingate_connector_sg" {
  source = "./modules/security-groups"
  name   = "twingate-connector-sg"
  vpc_id = module.twingate_vpc.vpc_id
  ingress_rules = [
    {
      description     = "Twingate HTTPS Traffic"
      from_port       = 443
      to_port         = 443
      protocol        = "tcp"
      security_groups = []
      cidr_blocks     = ["0.0.0.0/0"]
    },
    {
      description     = "Twingate Data Plane"
      from_port       = 30000
      to_port         = 31000
      protocol        = "udp"
      security_groups = []
      cidr_blocks     = ["0.0.0.0/0"]
    }
  ]
  egress_rules = [
    {
      description     = "Allow all outbound"
      from_port       = 0
      to_port         = 0
      protocol        = "-1"
      cidr_blocks     = ["0.0.0.0/0"]
      security_groups = []
    }
  ]
  tags = {
    Name = "twingate-connector-sg"
  }
}

module "lb_sg" {
  source = "./modules/security-groups"
  name   = "lb-sg"
  vpc_id = module.twingate_vpc.vpc_id
  ingress_rules = [
    {
      description     = "HTTP Traffic"
      from_port       = 80
      to_port         = 80
      protocol        = "tcp"
      security_groups = [module.twingate_connector_sg.id]
      cidr_blocks     = []
    },
    {
      description     = "HTTPS Traffic"
      from_port       = 443
      to_port         = 443
      protocol        = "tcp"
      security_groups = [module.twingate_connector_sg.id]
      cidr_blocks     = []
    }
  ]
  egress_rules = [
    {
      description = "Allow all outbound traffic"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
  tags = {
    Name = "lb-sg"
  }
}

module "asg_sg" {
  source = "./modules/security-groups"
  name   = "asg-sg"
  vpc_id = module.twingate_vpc.vpc_id
  ingress_rules = [
    {
      description     = "HTTP Traffic"
      from_port       = 80
      to_port         = 80
      protocol        = "tcp"
      security_groups = [module.lb_sg.id]
      cidr_blocks     = []
    },
    {
      description     = "SSH Traffic"
      from_port       = 22
      to_port         = 22
      protocol        = "tcp"
      security_groups = []
      cidr_blocks     = ["0.0.0.0/0"]
    }
  ]
  egress_rules = [
    {
      description = "Allow all outbound traffic"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
  tags = {
    Name = "asg-sg"
  }
}

# -------------------------------------------------------------------------------
# Auto Scaling Group
# -------------------------------------------------------------------------------
resource "aws_iam_role" "ec2_role" {
  name = "ec2-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_instance_profile" "iam_instance_profile" {
  name = "ec2-instance-profile"
  role = aws_iam_role.ec2_role.name
}

# Instance template
module "launch_template" {
  source                               = "./modules/launch-template"
  name                                 = var.launch_template_name
  description                          = var.launch_template_name
  ebs_optimized                        = false
  image_id                             = var.asg_ami_id
  instance_type                        = var.asg_instance_type
  instance_initiated_shutdown_behavior = "stop"
  instance_profile_name                = aws_iam_instance_profile.iam_instance_profile.name
  key_name                             = data.aws_key_pair.key_pair.key_name
  network_interfaces = [
    {
      associate_public_ip_address = false
      security_groups             = [module.asg_sg.id]
    }
  ]
  user_data = base64encode(templatefile("${path.module}/scripts/user_data.sh", {}))
}

# Auto Scaling Group for launch template
module "asg" {
  source                    = "./modules/auto-scaling-group"
  name                      = var.asg_name
  min_size                  = var.asg_min_size
  max_size                  = var.asg_max_size
  desired_capacity          = var.asg_desired_capacity
  health_check_grace_period = 300
  health_check_type         = "ELB"
  force_delete              = true
  target_group_arns         = [module.lb.target_groups.lb_target_group.arn]
  vpc_zone_identifier       = module.twingate_vpc.private_subnets
  launch_template_id        = module.launch_template.id
  launch_template_version   = "$Latest"
}

# -------------------------------------------------------------------------------
# Load Balancer
# -------------------------------------------------------------------------------
module "lb_logs" {
  source      = "./modules/s3"
  bucket_name = "lb-logs-${random_id.id.hex}"
  region      = var.region
  objects     = []
  bucket_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSLogDeliveryWrite"
        Effect = "Allow"
        Principal = {
          Service = "logging.s3.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "arn:aws:s3:::lb-logs-${random_id.id.hex}/*"
      },
      {
        Sid    = "AWSLogDeliveryAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "logging.s3.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = "arn:aws:s3:::lb-logs-${random_id.id.hex}"
      },
      {
        Sid    = "AWSELBAccountWrite"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_elb_service_account.elb_service_account.id}:root"
        }
        Action   = "s3:PutObject"
        Resource = "arn:aws:s3:::lb-logs-${random_id.id.hex}/*"
      }
    ]
  })
  cors = [
    {
      allowed_headers = ["*"]
      allowed_methods = ["GET"]
      allowed_origins = ["*"]
      max_age_seconds = 3000
    },
    {
      allowed_headers = ["*"]
      allowed_methods = ["PUT"]
      allowed_origins = ["*"]
      max_age_seconds = 3000
    }
  ]
  versioning_enabled = "Enabled"
  force_destroy      = true
}

module "lb" {
  source                     = "terraform-aws-modules/alb/aws"
  name                       = var.lb_name
  load_balancer_type         = "application"
  vpc_id                     = module.twingate_vpc.vpc_id
  subnets                    = module.twingate_vpc.private_subnets
  enable_deletion_protection = false
  drop_invalid_header_fields = true
  ip_address_type            = "ipv4"
  internal                   = true
  security_groups = [
    module.lb_sg.id
  ]
  access_logs = {
    bucket = "${module.lb_logs.bucket}"
  }
  listeners = {
    lb_http_listener = {
      port     = 80
      protocol = "HTTP"
      forward = {
        target_group_key = "lb_target_group"
      }
    }
  }
  target_groups = {
    lb_target_group = {
      backend_protocol = "HTTP"
      backend_port     = 80
      target_type      = "instance"
      health_check = {
        enabled             = true
        healthy_threshold   = 3
        interval            = 30
        path                = "/"
        port                = 80
        protocol            = "HTTP"
        unhealthy_threshold = 3
      }
      create_attachment = false
    }
  }
  tags = {
    Name = var.lb_name
  }
}

module "twingate_connector_instance" {
  source = "./modules/ec2"

  instance_name               = "Twingate Connector"
  ami_id                      = data.aws_ami.twingate.id
  instance_type               = var.twingate_instance_type
  key_name                    = data.aws_key_pair.key_pair.key_name
  subnet_id                   = module.twingate_vpc.public_subnets[0]
  security_group_ids          = [module.twingate_connector_sg.id]
  associate_public_ip_address = true
  monitoring                  = true

  metadata_options = {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  user_data = <<-EOT
    #!/bin/bash
    set -e
    sleep 10
    mkdir -p /etc/twingate/
    {
      echo TWINGATE_URL="https://${var.tg_network}.twingate.com"
      echo TWINGATE_ACCESS_TOKEN="${module.twingate_module.first_connector_access_token}"
      echo TWINGATE_REFRESH_TOKEN="${module.twingate_module.first_connector_refresh_token}"
    } > /etc/twingate/connector.conf
    chmod 600 /etc/twingate/connector.conf
    sudo systemctl enable --now twingate-connector
    systemctl status twingate-connector > /var/log/twingate-startup.log 2>&1
  EOT

  tags = {
    Name    = "Twingate Connector"
    Project = var.project_name
  }
}

module "twingate_module" {
  source = "./modules/twingate-module"

  remote_network_name = var.twingate_network_name

  connectors = [
    {
      name = "aws-connector"
    }
  ]

  users = [
    {
      first_name = var.twingate_user_first_name
      last_name  = var.twingate_user_last_name
      email      = var.twingate_user_email
      role       = "ADMIN"
      is_active  = true
    }
  ]

  groups = [
    {
      name     = var.twingate_group_name
      user_ids = [module.twingate_module.user_ids[var.twingate_user_email], local.existing_user_id]
    }
  ]

  resources = [
    {
      name    = var.twingate_resource_name
      address = module.lb.dns_name
      protocols = {
        allow_icmp = true
        tcp = {
          policy = "RESTRICTED"
          ports  = ["80"]
        }
        udp = {
          policy = "ALLOW_ALL"
        }
      }
      access_groups = [
        {
          group_id           = module.twingate_module.group_ids[var.twingate_group_name]
          security_policy_id = null
        }
      ]
    }
  ]
}