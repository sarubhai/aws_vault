# Name: variables.tf
# Owner: Saurav Mitra
# Description: Variables used by terraform config to create a VPC & Subnets

variable "prefix" {
  description = "This prefix will be included in the name of the resources."
}

variable "owner" {
  description = "This owner name tag will be included in the name of the resources."
}

variable "vpc_cidr_block" {
  description = "The address space that is used by the virtual network."
}

variable "public_subnets" {
  description = "A map of availability zones to CIDR blocks to use for the public subnet."
}

variable "private_subnets" {
  description = "A map of availability zones to CIDR blocks to use for the private subnet."
}
