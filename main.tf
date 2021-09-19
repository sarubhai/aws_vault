# main.tf
# Owner: Saurav Mitra
# Description: This terraform config will create the infrastructure resources for Vault

# VPC & Subnets
module "vpc" {
  source          = "./vpc"
  prefix          = var.prefix
  owner           = var.owner
  vpc_cidr_block  = var.vpc_cidr_block
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
}

# Security Groups
module "sg" {
  source              = "./sg"
  prefix              = var.prefix
  owner               = var.owner
  vpc_id              = module.vpc.vpc_id
  vpc_cidr_block      = var.vpc_cidr_block
  internet_cidr_block = var.internet_cidr_block
}

# Instances
module "instances" {
  source               = "./instances"
  prefix               = var.prefix
  owner                = var.owner
  region               = var.region
  vpc_id               = module.vpc.vpc_id
  public_subnet_id     = module.vpc.public_subnet_id
  private_subnet_id    = module.vpc.private_subnet_id
  fixed_pvt_ip         = var.fixed_pvt_ip
  vault_sg_id          = module.sg.vault_sg_id
  database_sg_id       = module.sg.database_sg_id
  minikube_sg_id       = module.sg.minikube_sg_id
  domain               = var.domain
  vault_dc1_instances  = var.vault_dc1_instances
  vault_dc2_instances  = var.vault_dc2_instances
  vault_dc3_instances  = var.vault_dc3_instances
  keypair_name         = var.keypair_name
  s3_bucket_name       = var.s3_bucket_name
  vault_license        = var.vault_license
  database_instance    = var.database_instance
  vault_admin_password = var.vault_admin_password
  minikube_instance    = var.minikube_instance
}


# Connect to VPC using OpenVPN Access Server
module "openvpn" {
  source                       = "./openvpn"
  prefix                       = var.prefix
  owner                        = var.owner
  vpc_id                       = module.vpc.vpc_id
  public_subnet_id             = module.vpc.public_subnet_id
  openvpn_server_ami_name      = var.openvpn_server_ami_name
  openvpn_server_instance_type = var.openvpn_server_instance_type
  vpn_admin_user               = var.vpn_admin_user
  vpn_admin_password           = var.vpn_admin_password
  keypair_name                 = var.keypair_name
}
