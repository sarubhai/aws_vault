# variables.tf
# Owner: Saurav Mitra
# Description: Variables used by terraform config to create the infrastructure resources for Vault
# https://www.terraform.io/docs/configuration/variables.html

# AWS EC2 KeyPair
variable "keypair_name" {
  description = "The AWS Key pair name."
}

variable "region" {
  description = "The region where the resources are created."
  default     = "us-east-2"
}


# Tags
variable "prefix" {
  description = "This prefix will be included in the name of the resources."
  default     = "Vault"
}

variable "owner" {
  description = "This owner name tag will be included in the owner of the resources."
  default     = "Saurav Mitra"
}


# VPC & Subnets
variable "vpc_cidr_block" {
  description = "The address space that is used by the virtual network."
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "A map of availability zones to CIDR blocks to use for the public subnet."
  default = {
    us-east-2a = "10.0.0.0/24"
  }
}

variable "private_subnets" {
  description = "A map of availability zones to CIDR blocks to use for the private subnet."
  default = {
    us-east-2a = "10.0.1.0/24"
    us-east-2b = "10.0.2.0/24"
    us-east-2c = "10.0.3.0/24"
  }
}

variable "internet_cidr_block" {
  description = "The address space that is used by the internet."
  default     = "0.0.0.0/0"
}

variable "fixed_pvt_ip" {
  description = "Fixed Private IP's with all in the first private subnet."
  default     = true
}

# Instances
variable "vault_dc1_instances" {
  description = "The Vault DC1 Instances."
  default     = { instance_type : "t2.micro", volume : 30, count : 3, pvt_ips : ["10.0.1.91", "10.0.1.92", "10.0.1.93"], nodes : ["dc1-vault1", "dc1-vault2", "dc1-vault3"] }
}

variable "vault_dc2_instances" {
  description = "The Vault DC2 Instances."
  default     = { instance_type : "t2.micro", volume : 30, count : 3, pvt_ips : ["10.0.2.91", "10.0.2.92", "10.0.2.93"], nodes : ["dc2-vault1", "dc2-vault2", "dc2-vault3"] }
}

variable "vault_dc3_instances" {
  description = "The Vault DC3 Instances."
  default     = { instance_type : "t2.micro", volume : 30, count : 3, pvt_ips : ["10.0.3.91", "10.0.3.92", "10.0.3.93"], nodes : ["dc3-vault1", "dc3-vault2", "dc3-vault3"] }
}

variable "s3_bucket_name" {
  description = "The S3 bucket name having the custom CA cert & TLS cert & key for all the servers."
}

variable "vault_license" {
  description = "The Vault Enterprise License."
}

variable "database_instance" {
  description = "The Database Server Instance."
  default     = { instance_type : "t2.large", pvt_ip : "10.0.1.100" }
}

variable "vault_admin_password" {
  description = "The Admin Password for various Vault Auth."
  default     = "Password123456"
}


# OpenVPN Access Server
variable "openvpn_server_ami_name" {
  description = "The OpenVPN Access Server AMI Name."
  default     = "OpenVPN Access Server Community Image-fe8020db-5343-4c43-9e65-5ed4a825c931-ami-06585f7cf2fb8855c.4"
}

variable "openvpn_server_instance_type" {
  description = "The OpenVPN Access Server Instance Type."
  default     = "t2.micro"
}

variable "vpn_admin_user" {
  description = "The OpenVPN Admin User."
  default     = "openvpn"
}

variable "vpn_admin_password" {
  description = "The OpenVPN Admin Password."
}
