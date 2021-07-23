# outputs.tf
# Owner: Saurav Mitra
# Description: Outputs the relevant resources ID, ARN, URL values
# https://www.terraform.io/docs/configuration/outputs.html

/*
# VPC & Subnet
output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "The VPC ID."
}

output "public_subnet_id" {
  value       = module.vpc.public_subnet_id
  description = "The public subnets ID."
}

output "private_subnet_id" {
  value       = module.vpc.private_subnet_id
  description = "The private subnets ID."
}

# Security Groups
output "vault_sg_id" {
  value       = module.sg.vault_sg_id
  description = "Security Group for Vault."
}

*/

# Instances
output "vault_dc1_instances_ip" {
  value       = module.instances.vault_dc1_instances_ip
  description = "The Vault DC1 Instances IP's."
}

output "vault_dc2_instances_ip" {
  value       = module.instances.vault_dc2_instances_ip
  description = "The Vault DC2 Instances IP's."
}

output "vault_dc3_instances_ip" {
  value       = module.instances.vault_dc3_instances_ip
  description = "The Vault DC3 Instances IP's."
}

output "database_server_ip" {
  value       = module.instances.database_server_ip
  description = "Database Server IP."
}


# OpenVPN Access Server
output "openvpn_access_server_ip" {
  value       = "https://${module.openvpn.openvpn_access_server_ip}:943/"
  description = "OpenVPN Access Server IP."
}
