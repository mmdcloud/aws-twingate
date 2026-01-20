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
  vpc_name                = "twingate-vpc"
  vpc_cidr                = "10.0.0.0/16"
  azs                     = var.azs
  public_subnets          = var.public_subnets
  private_subnets         = var.private_subnets
  enable_dns_hostnames    = true
  enable_dns_support      = true
  create_igw              = true
  map_public_ip_on_launch = true
  enable_nat_gateway      = true
  single_nat_gateway      = true
  one_nat_gateway_per_az  = false
  tags = {
    Project = "twingate"
  }
}

# Security Group
module "twingate_connector_sg" {
  source = "./modules/security-groups"
  name   = "twingate-connector-sg"
  vpc_id = module.twingate_vpc.vpc_id
  ingress_rules = [
    {
      description     = "Twingate Control Plane"
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

module "vm_sg" {
  source = "./modules/security-groups"
  name   = "vm-sg"
  vpc_id = module.twingate_vpc.vpc_id
  ingress_rules = [
    {
      description     = "HTTP from Twingate Connector"
      from_port       = 80
      to_port         = 80
      protocol        = "tcp"
      security_groups = [module.twingate_connector_sg.id]
      cidr_blocks     = []
    },
    {
      description     = "SSH from Twingate Connector"
      from_port       = 22
      to_port         = 22
      protocol        = "tcp"
      security_groups = [module.twingate_connector_sg.id]
      cidr_blocks     = []
    },
    {
      description     = "ICMP from Twingate Connector"
      from_port       = -1
      to_port         = -1
      protocol        = "icmp"
      security_groups = [module.twingate_connector_sg.id]
      cidr_blocks     = []
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
    Name = "demo-vm-sg"
  }
}

# -----------------------------------------------------------------------------------------
# Twingate Configuration
# -----------------------------------------------------------------------------------------
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
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  key_name               = data.aws_key_pair.key_pair.key_name
  subnet_id              = module.twingate_vpc.private_subnets[0]
  vpc_security_group_ids = [module.vm_sg.id]
  user_data              = <<-EOT
    #!/bin/bash
    apt-get update
    apt-get install -y nginx
    echo "<h1>Hello from Twingate Demo VM</h1>" > /var/www/html/index.html
    systemctl enable nginx
    systemctl start nginx
  EOT
  tags = {
    "Name" = "Demo VM"
  }
}

resource "aws_instance" "twingate_connector" {
  ami                         = data.aws_ami.twingate.id
  instance_type               = "t3.micro"
  associate_public_ip_address = true
  vpc_security_group_ids      = [module.twingate_connector_sg.id]
  key_name                    = data.aws_key_pair.key_pair.key_name
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
  monitoring = true
  user_data  = <<-EOT
    #!/bin/bash
    set -e
    sleep 10
    mkdir -p /etc/twingate/
    {
      echo TWINGATE_URL="https://${var.tg_network}.twingate.com"
      echo TWINGATE_ACCESS_TOKEN="${twingate_connector_tokens.aws_connector_tokens.access_token}"
      echo TWINGATE_REFRESH_TOKEN="${twingate_connector_tokens.aws_connector_tokens.refresh_token}"
    } > /etc/twingate/connector.conf
    chmod 600 /etc/twingate/connector.conf
    sudo systemctl enable --now twingate-connector
    systemctl status twingate-connector > /var/log/twingate-startup.log 2>&1
  EOT
  subnet_id  = module.twingate_vpc.public_subnets[0]
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

resource "twingate_user" "user" {
  first_name = "mohit"
  last_name  = "dixit"
  role       = "ADMIN"
  is_active  = true
  email      = "madmaxcloudonline@gmail.com"
}

resource "twingate_group" "aws_group" {
  name     = "aws group"
  user_ids = [twingate_user.user.id]
}

resource "twingate_resource" "aws_resource" {
  name              = "aws web sever"
  address           = aws_instance.instance.private_ip
  remote_network_id = twingate_remote_network.aws_network.id
  protocols = {
    allow_icmp = true
    tcp = {
      policy = "RESTRICTED"
      ports  = ["22"]
    }
    udp = {
      policy = "ALLOW_ALL"
    }
  }
  access_group {
    group_id           = twingate_group.aws_group.id
    security_policy_id = null
  }
}