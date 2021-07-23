# Name: variables.tf
# Owner: Saurav Mitra
# Description: Variables used by terraform config to create EC2 instance for OpenVPN Access Server

variable "prefix" {
  description = "This prefix will be included in the name of the resources."
}

variable "owner" {
  description = "This owner name tag will be included in the name of the resources."
}

variable "vpc_id" {
  description = "The VPC ID."
}

variable "public_subnet_id" {
  description = "The public subnets ID."
}

variable "openvpn_server_ami_name" {
  description = "The OpenVPN Access Server AMI Name."
}

variable "openvpn_server_instance_type" {
  description = "The OpenVPN Access Server Instance Type."
}

variable "vpn_admin_user" {
  description = "The OpenVPN Admin User."
}

variable "vpn_admin_password" {
  description = "The OpenVPN Admin Password."
}

variable "keypair_name" {
  description = "The AWS Key pair name."
}
