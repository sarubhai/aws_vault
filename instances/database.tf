# Name: database.tf
# Owner: Saurav Mitra
# Description: This terraform config will create a EC2 instance for Database Server


# Ansible AMI Filter
data "aws_ami" "database_centos" {
  owners      = ["679593333241"] # Canonical
  most_recent = true

  filter {
    name   = "name"
    values = ["CentOS Linux 7 x86_64 HVM EBS *"]
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
data "template_file" "database_init_script" {
  template = templatefile("${path.module}/database_server.sh", {
    vault_admin_password = var.vault_admin_password
  })
}


# EC2 Instance
resource "aws_instance" "database-server" {
  ami                    = data.aws_ami.database_centos.id
  instance_type          = var.database_instance["instance_type"]
  subnet_id              = var.private_subnet_id[0]
  private_ip             = var.fixed_pvt_ip ? var.database_instance["pvt_ip"] : null
  vpc_security_group_ids = [var.database_sg_id]
  key_name               = var.keypair_name
  source_dest_check      = false

  root_block_device {
    volume_size           = 30
    delete_on_termination = true
  }

  tags = {
    Name  = "${var.prefix}-database-server"
    Owner = var.owner
  }

  user_data = data.template_file.database_init_script.rendered
}
