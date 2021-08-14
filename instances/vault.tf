# Name: vault.tf
# Owner: Saurav Mitra
# Description: This terraform config will create EC2 instances & KMS for Vault


# Vault AMI Filter
data "aws_ami" "confluent_centos" {
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

# AWS KMS Auto Unseal
resource "aws_kms_key" "vault_kms" {
  description = "Vault KMS"

  tags = {
    Name  = "${var.prefix}-kms"
    Owner = var.owner
  }
}

resource "aws_kms_alias" "vault_kms_alias" {
  name          = "alias/vault-kms"
  target_key_id = aws_kms_key.vault_kms.key_id
}

resource "aws_iam_role" "vault_kms_role" {
  name = "vault_kms_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  inline_policy {
    name = "kms_policy"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action   = ["kms:Encrypt", "kms:Decrypt", "kms:DescribeKey"]
          Effect   = "Allow"
          Resource = "*"
        },
        {
          Action   = ["s3:List*", "s3:Get*"]
          Effect   = "Allow"
          Resource = "*"
        },
      ]
    })
  }

  tags = {
    Name  = "${var.prefix}-kms-role"
    Owner = var.owner
  }
}

resource "aws_iam_instance_profile" "vault_kms_profile" {
  name = "vault_kms_profile"
  role = aws_iam_role.vault_kms_role.name
}


# EC2 Instances
resource "aws_instance" "vault_dc1" {
  count                  = var.vault_dc1_instances["count"]
  ami                    = data.aws_ami.confluent_centos.id
  instance_type          = var.vault_dc1_instances["instance_type"]
  subnet_id              = var.private_subnet_id[0]
  private_ip             = var.fixed_pvt_ip ? var.vault_dc1_instances["pvt_ips"][count.index] : null
  vpc_security_group_ids = [var.vault_sg_id]
  key_name               = var.keypair_name
  source_dest_check      = false
  iam_instance_profile   = aws_iam_instance_profile.vault_kms_profile.name

  root_block_device {
    volume_size           = var.vault_dc1_instances["volume"]
    delete_on_termination = true
  }

  user_data = templatefile("${path.module}/userdata-vault-server.tpl", {
    cluster                  = "dc1",
    domain                   = var.domain,
    vault_node_name          = var.vault_dc1_instances["nodes"][count.index],
    vault_node_address_names = zipmap(var.vault_dc1_instances["pvt_ips"], var.vault_dc1_instances["nodes"]),
    all_node_address_names   = merge(zipmap(var.vault_dc1_instances["pvt_ips"], var.vault_dc1_instances["nodes"]), zipmap(var.vault_dc2_instances["pvt_ips"], var.vault_dc2_instances["nodes"]), zipmap(var.vault_dc3_instances["pvt_ips"], var.vault_dc3_instances["nodes"])),
    kms_key_id               = aws_kms_key.vault_kms.key_id
    kms_region               = var.region
    s3_bucket_name           = var.s3_bucket_name
    vault_license            = var.vault_license
  })

  tags = {
    Name  = "${var.prefix}-vault_dc1-${count.index + 1}"
    Owner = var.owner
  }
}

resource "aws_instance" "vault_dc2" {
  count                  = var.vault_dc2_instances["count"]
  ami                    = data.aws_ami.confluent_centos.id
  instance_type          = var.vault_dc2_instances["instance_type"]
  subnet_id              = var.private_subnet_id[1]
  private_ip             = var.fixed_pvt_ip ? var.vault_dc2_instances["pvt_ips"][count.index] : null
  vpc_security_group_ids = [var.vault_sg_id]
  key_name               = var.keypair_name
  source_dest_check      = false
  iam_instance_profile   = aws_iam_instance_profile.vault_kms_profile.name

  root_block_device {
    volume_size           = var.vault_dc2_instances["volume"]
    delete_on_termination = true
  }

  user_data = templatefile("${path.module}/userdata-vault-server.tpl", {
    cluster                  = "dc2",
    domain                   = var.domain,
    vault_node_name          = var.vault_dc2_instances["nodes"][count.index],
    vault_node_address_names = zipmap(var.vault_dc2_instances["pvt_ips"], var.vault_dc2_instances["nodes"]),
    all_node_address_names   = merge(zipmap(var.vault_dc1_instances["pvt_ips"], var.vault_dc1_instances["nodes"]), zipmap(var.vault_dc2_instances["pvt_ips"], var.vault_dc2_instances["nodes"]), zipmap(var.vault_dc3_instances["pvt_ips"], var.vault_dc3_instances["nodes"])),
    kms_key_id               = aws_kms_key.vault_kms.key_id
    kms_region               = var.region
    s3_bucket_name           = var.s3_bucket_name
    vault_license            = var.vault_license
  })

  tags = {
    Name  = "${var.prefix}-vault_dc2-${count.index + 1}"
    Owner = var.owner
  }
}

resource "aws_instance" "vault_dc3" {
  count                  = var.vault_dc3_instances["count"]
  ami                    = data.aws_ami.confluent_centos.id
  instance_type          = var.vault_dc3_instances["instance_type"]
  subnet_id              = var.private_subnet_id[2]
  private_ip             = var.fixed_pvt_ip ? var.vault_dc3_instances["pvt_ips"][count.index] : null
  vpc_security_group_ids = [var.vault_sg_id]
  key_name               = var.keypair_name
  source_dest_check      = false
  iam_instance_profile   = aws_iam_instance_profile.vault_kms_profile.name

  root_block_device {
    volume_size           = var.vault_dc3_instances["volume"]
    delete_on_termination = true
  }

  user_data = templatefile("${path.module}/userdata-vault-server.tpl", {
    cluster                  = "dc3",
    domain                   = var.domain,
    vault_node_name          = var.vault_dc3_instances["nodes"][count.index],
    vault_node_address_names = zipmap(var.vault_dc3_instances["pvt_ips"], var.vault_dc3_instances["nodes"]),
    all_node_address_names   = merge(zipmap(var.vault_dc1_instances["pvt_ips"], var.vault_dc1_instances["nodes"]), zipmap(var.vault_dc2_instances["pvt_ips"], var.vault_dc2_instances["nodes"]), zipmap(var.vault_dc3_instances["pvt_ips"], var.vault_dc3_instances["nodes"])),
    kms_key_id               = aws_kms_key.vault_kms.key_id
    kms_region               = var.region
    s3_bucket_name           = var.s3_bucket_name
    vault_license            = var.vault_license
  })

  tags = {
    Name  = "${var.prefix}-vault_dc3-${count.index + 1}"
    Owner = var.owner
  }
}
