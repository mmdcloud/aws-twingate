resource "random_id" "id" {
  byte_length = 8
}

# -----------------------------------------------------------------------------------------
# VPC Configuration
# -----------------------------------------------------------------------------------------

module "vpc" {
  source                = "./modules/vpc/vpc"
  vpc_name              = "vpc"
  vpc_cidr_block        = "10.0.0.0/16"
  enable_dns_hostnames  = true
  enable_dns_support    = true
  internet_gateway_name = "vpc_igw"
}

# Security Group
module "redshift_security_group" {
  source = "./modules/vpc/security_groups"
  vpc_id = module.vpc.vpc_id
  name   = "redshift-security-group"
  ingress = [
    {
      from_port       = 5439
      to_port         = 5439
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
module "public_subnets" {
  source = "./modules/vpc/subnets"
  name   = "public-subnet"
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
  vpc_id                  = module.vpc.vpc_id
  map_public_ip_on_launch = true
}

# Private Subnets
module "private_subnets" {
  source = "./modules/vpc/subnets"
  name   = "private-subnet"
  subnets = [
    {
      subnet = "10.0.7.0/24"
      az     = "${var.region}a"
    },
    {
      subnet = "10.0.8.0/24"
      az     = "${var.region}b"
    },
    {
      subnet = "10.0.9.0/24"
      az     = "${var.region}c"
    }
  ]
  vpc_id                  = module.vpc.vpc_id
  map_public_ip_on_launch = false
}

# Public Route Table
module "public_rt" {
  source  = "./modules/vpc/route_tables"
  name    = "public-route-table"
  subnets = module.public_subnets.subnets[*]
  routes = [
    {
      cidr_block         = "0.0.0.0/0"
      gateway_id         = module.vpc.igw_id
      nat_gateway_id     = ""
      transit_gateway_id = ""
    }
  ]
  vpc_id = module.vpc.vpc_id
}

# Private Route Table
module "private_rt" {
  source  = "./modules/vpc/route_tables"
  name    = "private-route-table"
  subnets = module.private_subnets.subnets[*]
  routes  = []
  vpc_id  = module.vpc.vpc_id
}