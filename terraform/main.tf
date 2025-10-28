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
  source = "./modules/vpc"
  vpc_name = "twingate-vpc"
  vpc_cidr = "10.0.0.0/16"
  azs             = var.azs
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
  enable_dns_hostnames = true
  enable_dns_support   = true
  create_igw = true
  map_public_ip_on_launch = true
  enable_nat_gateway     = false
  single_nat_gateway     = false
  one_nat_gateway_per_az = false
  tags = {
    Project     = "twingate"
  }
}

# Security Group
resource "aws_security_group" "twingate_security_group" {
  name        = "twingate-sg"
  vpc_id      = module.twingate_vpc.vpc_id

  ingress {
    description = "HTTP traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "twingate-sg"
  }
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
  subnet_id     = module.twingate_vpc.private_subnets[0]
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
  subnet_id                   = module.twingate_vpc.public_subnets[0]
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