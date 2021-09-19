# Name: minikube.tf
# Owner: Saurav Mitra
# Description: This terraform config will create a EC2 instance for Minikube Server


# Ansible AMI Filter
data "aws_ami" "minikube_ubuntu" {
  owners      = ["099720109477"] # Canonical
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


# User Data Init
data "template_file" "minikube_init_script" {
  template = templatefile("${path.module}/minikube_server.sh", {
    vault_admin_password = var.vault_admin_password
  })
}


# EC2 Instance
resource "aws_instance" "minikube-server" {
  ami                    = data.aws_ami.minikube_ubuntu.id
  instance_type          = var.minikube_instance["instance_type"]
  subnet_id              = var.private_subnet_id[0]
  private_ip             = var.fixed_pvt_ip ? var.minikube_instance["pvt_ip"] : null
  vpc_security_group_ids = [var.minikube_sg_id]
  key_name               = var.keypair_name
  source_dest_check      = false

  root_block_device {
    volume_size           = 30
    delete_on_termination = true
  }

  tags = {
    Name  = "${var.prefix}-minikube-server"
    Owner = var.owner
  }

  user_data = data.template_file.minikube_init_script.rendered
}
