# -----------------------------------------------------------------------------------------
# General Variables
# -----------------------------------------------------------------------------------------
region              = "us-east-1"
project_name        = "twingate"
key_pair_name       = "madmaxkeypair"
existing_user_email = "mohitfury1997@gmail.com"

# -----------------------------------------------------------------------------------------
# VPC Variables
# -----------------------------------------------------------------------------------------
vpc_name        = "twingate-vpc"
vpc_cidr        = "10.0.0.0/16"
azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
public_subnets  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
private_subnets = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

# -----------------------------------------------------------------------------------------
# EC2 IAM Variables
# -----------------------------------------------------------------------------------------
ec2_managed_policy_arns = [
  "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
]

# -----------------------------------------------------------------------------------------
# Launch Template & ASG Variables
# -----------------------------------------------------------------------------------------
launch_template_name = "launch_template"
asg_ami_id           = "ami-005fc0f236362e99f"
asg_instance_type    = "t2.micro"
asg_name             = "asg"
asg_min_size         = 3
asg_max_size         = 50
asg_desired_capacity = 3

# -----------------------------------------------------------------------------------------
# Load Balancer Variables
# -----------------------------------------------------------------------------------------
lb_name = "twingate-lb"

# -----------------------------------------------------------------------------------------
# Twingate Connector Variables
# -----------------------------------------------------------------------------------------
twingate_instance_type = "t2.micro"
tg_network             = "mohitfury1997"

# -----------------------------------------------------------------------------------------
# Twingate Configuration Variables
# -----------------------------------------------------------------------------------------
twingate_network_name    = "aws remote network"
twingate_user_first_name = "mohit"
twingate_user_last_name  = "dixit"
twingate_user_email      = "madmaxcloudonline@gmail.com"
twingate_group_name      = "aws group"
twingate_resource_name   = "aws web sever"