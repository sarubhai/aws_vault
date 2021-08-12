# Name: variables.tf
# Owner: Saurav Mitra
# Description: Variables used by terraform config to create EC2 instances for Vault

variable "prefix" {
  description = "This prefix will be included in the name of the resources."
}

variable "owner" {
  description = "This owner name tag will be included in the name of the resources."
}

variable "region" {
  description = "The region where the resources are created."
}

variable "vpc_id" {
  description = "The VPC ID."
}

variable "public_subnet_id" {
  description = "The public subnets ID."
}

variable "private_subnet_id" {
  description = "The private subnets ID."
}

variable "fixed_pvt_ip" {
  description = "Fixed Private IP's with all in the first private subnet."
}

variable "vault_sg_id" {
  description = "Security Group for Vault."
}

variable "database_sg_id" {
  description = "Security Group for Database Server."
}

variable "domain" {
  description = "DNS Domain Name."
}

variable "vault_dc1_instances" {
  description = "The Vault DC1 Instances."
}

variable "vault_dc2_instances" {
  description = "The Vault DC2 Instances."
}

variable "vault_dc3_instances" {
  description = "The Vault DC3 Instances."
}

variable "keypair_name" {
  description = "The AWS Key pair name."
}

variable "s3_bucket_name" {
  description = "The S3 bucket name having the custom CA cert & TLS cert & key for all the servers."
}

variable "vault_license" {
  description = "The Vault Enterprise License."
}

variable "database_instance" {
  description = "The Database Server Instance."
}

variable "vault_admin_password" {
  description = "The Admin Password for UserPass Auth."
}
