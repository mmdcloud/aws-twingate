# -----------------------------------------------------------------------------------------
# VPC Outputs
# -----------------------------------------------------------------------------------------
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.twingate_vpc.vpc_id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = module.twingate_vpc.vpc_cidr_block
}

output "public_subnets" {
  description = "List of public subnet IDs"
  value       = module.twingate_vpc.public_subnets
}

output "private_subnets" {
  description = "List of private subnet IDs"
  value       = module.twingate_vpc.private_subnets
}

# -----------------------------------------------------------------------------------------
# Security Group Outputs
# -----------------------------------------------------------------------------------------
output "twingate_connector_sg_id" {
  description = "ID of Twingate connector security group"
  value       = module.twingate_connector_sg.id
}

output "lb_sg_id" {
  description = "ID of load balancer security group"
  value       = module.lb_sg.id
}

output "asg_sg_id" {
  description = "ID of ASG security group"
  value       = module.asg_sg.id
}

# -----------------------------------------------------------------------------------------
# IAM Outputs
# -----------------------------------------------------------------------------------------
output "ec2_role_arn" {
  description = "ARN of EC2 IAM role"
  value       = aws_iam_role.ec2_role.arn
}

output "ec2_instance_profile_name" {
  description = "Name of EC2 instance profile"
  value       = aws_iam_instance_profile.iam_instance_profile.name
}

# -----------------------------------------------------------------------------------------
# Auto Scaling Group Outputs
# -----------------------------------------------------------------------------------------
output "asg_id" {
  description = "ID of the Auto Scaling Group"
  value       = module.asg.id
}

output "asg_arn" {
  description = "ARN of the Auto Scaling Group"
  value       = module.asg.arn
}

output "launch_template_id" {
  description = "ID of the launch template"
  value       = module.launch_template.id
}

# -----------------------------------------------------------------------------------------
# Load Balancer Outputs
# -----------------------------------------------------------------------------------------
output "lb_dns_name" {
  description = "DNS name of the load balancer"
  value       = module.lb.dns_name
}

output "lb_arn" {
  description = "ARN of the load balancer"
  value       = module.lb.arn
}

output "lb_zone_id" {
  description = "Zone ID of the load balancer"
  value       = module.lb.zone_id
}

output "lb_logs_bucket" {
  description = "S3 bucket for load balancer logs"
  value       = module.lb_logs.bucket
}

# -----------------------------------------------------------------------------------------
# Twingate Connector Instance Outputs
# -----------------------------------------------------------------------------------------
output "twingate_connector_id" {
  description = "ID of Twingate connector instance"
  value       = module.twingate_connector_instance.id
}

output "twingate_connector_public_ip" {
  description = "Public IP of Twingate connector"
  value       = module.twingate_connector_instance.public_ip
}

output "twingate_connector_private_ip" {
  description = "Private IP of Twingate connector"
  value       = module.twingate_connector_instance.private_ip
}

# -----------------------------------------------------------------------------------------
# Twingate Configuration Outputs
# -----------------------------------------------------------------------------------------
output "twingate_remote_network_id" {
  description = "ID of Twingate remote network"
  value       = module.twingate_module.remote_network_id
}

output "twingate_connector_ids" {
  description = "Map of Twingate connector IDs"
  value       = module.twingate_module.connector_ids
}

output "twingate_user_ids" {
  description = "Map of Twingate user IDs"
  value       = module.twingate_module.user_ids
}

output "twingate_group_ids" {
  description = "Map of Twingate group IDs"
  value       = module.twingate_module.group_ids
}

output "twingate_resource_ids" {
  description = "Map of Twingate resource IDs"
  value       = module.twingate_module.resource_ids
}

# -----------------------------------------------------------------------------------------
# Connection Information
# -----------------------------------------------------------------------------------------
output "ssh_connection_command" {
  description = "SSH command to connect to Twingate connector"
  value       = "ssh -i ~/.ssh/${var.key_pair_name}.pem ubuntu@${module.twingate_connector_instance.public_ip}"
}

output "load_balancer_endpoint" {
  description = "Load balancer endpoint"
  value       = "http://${module.lb.dns_name}"
}