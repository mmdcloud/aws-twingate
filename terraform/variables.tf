# -----------------------------------------------------------------------------------------
# General Variables
# -----------------------------------------------------------------------------------------
variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name for tagging"
  type        = string
  default     = "twingate"
}

variable "key_pair_name" {
  description = "Name of the EC2 key pair"
  type        = string
  default     = "madmaxkeypair"
}

variable "existing_user_email" {
  description = "Email of existing Twingate user to lookup"
  type        = string
  default     = "mohitfury1997@gmail.com"
}

# -----------------------------------------------------------------------------------------
# VPC Variables
# -----------------------------------------------------------------------------------------
variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
  default     = "twingate-vpc"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "Availability zones"
  type        = list(string)
}

variable "public_subnets" {
  description = "Public subnet CIDR blocks"
  type        = list(string)
}

variable "private_subnets" {
  description = "Private subnet CIDR blocks"
  type        = list(string)
}

# -----------------------------------------------------------------------------------------
# EC2 IAM Variables
# -----------------------------------------------------------------------------------------
variable "ec2_managed_policy_arns" {
  description = "List of managed policy ARNs to attach to EC2 role"
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------------------
# Launch Template & ASG Variables
# -----------------------------------------------------------------------------------------
variable "launch_template_name" {
  description = "Name of the launch template"
  type        = string
  default     = "launch_template"
}

variable "asg_ami_id" {
  description = "AMI ID for ASG instances"
  type        = string
  default     = "ami-005fc0f236362e99f"
}

variable "asg_instance_type" {
  description = "Instance type for ASG"
  type        = string
  default     = "t2.micro"
}

variable "asg_name" {
  description = "Name of the Auto Scaling Group"
  type        = string
  default     = "asg"
}

variable "asg_min_size" {
  description = "Minimum size of ASG"
  type        = number
  default     = 3
}

variable "asg_max_size" {
  description = "Maximum size of ASG"
  type        = number
  default     = 50
}

variable "asg_desired_capacity" {
  description = "Desired capacity of ASG"
  type        = number
  default     = 3
}

# -----------------------------------------------------------------------------------------
# Load Balancer Variables
# -----------------------------------------------------------------------------------------
variable "lb_name" {
  description = "Name of the load balancer"
  type        = string
  default     = "lb"
}

# -----------------------------------------------------------------------------------------
# Twingate Connector Variables
# -----------------------------------------------------------------------------------------
variable "twingate_instance_type" {
  description = "Instance type for Twingate connector"
  type        = string
  default     = "t3.micro"
}

variable "tg_network" {
  description = "Twingate network name"
  type        = string
}

# -----------------------------------------------------------------------------------------
# Twingate Configuration Variables
# -----------------------------------------------------------------------------------------
variable "twingate_network_name" {
  description = "Name of the Twingate remote network"
  type        = string
  default     = "aws remote network"
}

variable "twingate_user_first_name" {
  description = "First name of Twingate user"
  type        = string
  default     = "mohit"
}

variable "twingate_user_last_name" {
  description = "Last name of Twingate user"
  type        = string
  default     = "dixit"
}

variable "twingate_user_email" {
  description = "Email of Twingate user"
  type        = string
  default     = "madmaxcloudonline@gmail.com"
}

variable "twingate_group_name" {
  description = "Name of the Twingate group"
  type        = string
  default     = "aws group"
}

variable "twingate_resource_name" {
  description = "Name of the Twingate resource"
  type        = string
  default     = "aws web sever"
}