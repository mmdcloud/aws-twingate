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
  source                = "./modules/vpc/vpc"
  vpc_name              = "twingate-vpc"
  vpc_cidr_block        = "10.0.0.0/16"
  enable_dns_hostnames  = true
  enable_dns_support    = true
  internet_gateway_name = "vpc_igw"
}

# Security Group
module "twingate_security_group" {
  source = "./modules/vpc/security_groups"
  vpc_id = module.twingate_vpc.vpc_id
  name   = "twingate-sg"
  ingress = [
    {
      from_port       = 80
      to_port         = 80
      protocol        = "tcp"
      self            = "false"
      cidr_blocks     = ["0.0.0.0/0"]
      security_groups = []
      description     = "any"
    },
    {
      from_port       = 0
      to_port         = 0
      protocol        = "tcp"
      self            = "true"
      cidr_blocks     = ["0.0.0.0/0"]
      security_groups = []
      description     = "any"
    }
  ]
  egress = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

# Public Subnets
module "twingate_public_subnets" {
  source = "./modules/vpc/subnets"
  name   = "twingate-public-subnet"
  subnets = [
    {
      subnet = "10.0.1.0/24"
      az     = "${var.region}a"
    },
    {
      subnet = "10.0.2.0/24"
      az     = "${var.region}b"
    },
    {
      subnet = "10.0.3.0/24"
      az     = "${var.region}c"
    }
  ]
  vpc_id                  = module.twingate_vpc.vpc_id
  map_public_ip_on_launch = true
}

# Private Subnets
module "twingate_private_subnets" {
  source = "./modules/vpc/subnets"
  name   = "twingate-private-subnet"
  subnets = [
    {
      subnet = "10.0.4.0/24"
      az     = "${var.region}a"
    },
    {
      subnet = "10.0.5.0/24"
      az     = "${var.region}b"
    },
    {
      subnet = "10.0.6.0/24"
      az     = "${var.region}c"
    }
  ]
  vpc_id                  = module.twingate_vpc.vpc_id
  map_public_ip_on_launch = false
}

# Public Route Table
module "twingate_public_rt" {
  source  = "./modules/vpc/route_tables"
  name    = "twingate-public-route-table"
  subnets = module.twingate_public_subnets.subnets[*]
  routes = [
    {
      cidr_block         = "0.0.0.0/0"
      gateway_id         = module.twingate_vpc.igw_id
      nat_gateway_id     = ""
      transit_gateway_id = ""
    }
  ]
  vpc_id = module.twingate_vpc.vpc_id
}

# Private Route Table
module "twingate_private_rt" {
  source  = "./modules/vpc/route_tables"
  name    = "twingate-private-route-table"
  subnets = module.twingate_private_subnets.subnets[*]
  routes  = []
  vpc_id  = module.twingate_vpc.vpc_id
}

# -----------------------------------------------------------------------------------------
# Twingate Configuration
# -----------------------------------------------------------------------------------------

# Data Block top get latest ami
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
  owners = ["099720109477"] # Canonical
}

# Twingate AMI
data "aws_ami" "twingate" {
  most_recent = true
  filter {
    name   = "name"
    values = ["twingate/images/hvm-ssd/twingate-amd64-*"]
  }
  owners = ["617935088040"]
}

# Key pair
data "aws_key_pair" "key_pair" {
  key_name = "madmaxkeypair"
}

resource "aws_instance" "instance" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  key_name      = data.aws_key_pair.key_pair.key_name
  subnet_id     = module.twingate_private_subnets.subnets[0].id
  tags = {
    "Name" = "Demo VM"
  }
}

resource "aws_instance" "twingate_connector" {
  ami                         = data.aws_ami.twingate.id
  instance_type               = "t3.micro"
  associate_public_ip_address = true
  key_name                    = data.aws_key_pair.key_pair.key_name
  user_data                   = <<-EOT
    #!/bin/bash
    set -e
    mkdir -p /etc/twingate/
    {
      echo TWINGATE_URL="https://${var.tg_network}.twingate.com"
      echo TWINGATE_ACCESS_TOKEN="${twingate_connector_tokens.aws_connector_tokens.access_token}"
      echo TWINGATE_REFRESH_TOKEN="${twingate_connector_tokens.aws_connector_tokens.refresh_token}"
    } > /etc/twingate/connector.conf
    sudo systemctl enable --now twingate-connector
  EOT
  subnet_id                   = module.twingate_public_subnets.subnets[0].id
  tags = {
    "Name" = "Twingate Connector"
  }
}

resource "twingate_remote_network" "aws_network" {
  name = "aws remote network"
}

resource "twingate_connector" "aws_connector" {
  remote_network_id = twingate_remote_network.aws_network.id
}

resource "twingate_connector_tokens" "aws_connector_tokens" {
  connector_id = twingate_connector.aws_connector.id
}

resource "twingate_group" "aws_group" {
  name = "aws group"
}

resource "twingate_resource" "aws_resource" {
  name              = "aws web sever"
  address           = aws_instance.instance.private_ip
  remote_network_id = twingate_remote_network.aws_network.id
  access_group {
    group_id = twingate_group.aws_group.id
  }
}