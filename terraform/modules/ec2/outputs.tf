output "id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.this.id
}

output "arn" {
  description = "ARN of the EC2 instance"
  value       = aws_instance.this.arn
}

output "instance_state" {
  description = "State of the EC2 instance"
  value       = aws_instance.this.instance_state
}

output "public_ip" {
  description = "Public IP address of the instance"
  value       = aws_instance.this.public_ip
}

output "private_ip" {
  description = "Private IP address of the instance"
  value       = aws_instance.this.private_ip
}

output "public_dns" {
  description = "Public DNS name of the instance"
  value       = aws_instance.this.public_dns
}

output "private_dns" {
  description = "Private DNS name of the instance"
  value       = aws_instance.this.private_dns
}

output "availability_zone" {
  description = "Availability zone of the instance"
  value       = aws_instance.this.availability_zone
}

output "subnet_id" {
  description = "Subnet ID of the instance"
  value       = aws_instance.this.subnet_id
}

output "primary_network_interface_id" {
  description = "Primary network interface ID"
  value       = aws_instance.this.primary_network_interface_id
}