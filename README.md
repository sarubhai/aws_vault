# Vault cluster deployment in AWS

Deploys multiple HashiCorp Vault clusters in AWS using Terraform

The Cluster/Instances that will be deployed from this repository are:

- 3 Vault Cluster Nodes in DC1 as Primary Cluster
- 3 Vault Cluster Nodes in DC2 as DR Replication Cluster
- 3 Vault Cluster Nodes in DC3 as Performance Replication Cluster
- Vault's storage backend is Raft Integrated Storage
- Vault Cluster Nodes are TLS secured
- All the Vault Clusters Unseal is configured as Auto using AWS KMS
- 1 EC2 Instance installed with multiple demo database types

All Vault instances will be deployed in Private Subnet with fixed Private IP address.

## Vault Service Ports

- Vault API 8200
- Vault replication traffic and request forwarding 8201

## Add-On

### Demo for Vault Auth Methods & Secrets Engines

The Demo Database Server Instance have multiple database types running as docker containers;

- Oracle XE 11g
- MySQL
- PostgreSQL
- Elasticsearch
- MongoDB
- OpenLDAP
- RabbitMQ

### Vault Configuration using Terraform

- Use [https://github.com/sarubhai/aws_vault_config](https://github.com/sarubhai/aws_vault_config) repo to auto configure the Vault Cluster with multiple Auth methods & Secrets Engines.

## DR Primary Replication

### dc1 cluster node

vault write -f sys/replication/dr/primary/enable
vault write sys/replication/dr/primary/secondary-token id="dc2"

wrapping_token: eyJhbGciOiJFUzUxMiIsInR5cCI6IkpXVCJ9....

### dc2 cluster node

vault write sys/replication/dr/secondary/enable token=<wrapping_token>

vault read sys/replication/dr/status

#### Additional Failover Process:

- Demote DR Primary to Secondary
  [https://www.vaultproject.io/guides/operations/disaster-recovery#step4](https://www.vaultproject.io/guides/operations/disaster-recovery#step4)
- Disable DR Primary
  [https://www.vaultproject.io/guides/operations/disaster-recovery#step5](https://www.vaultproject.io/guides/operations/disaster-recovery#step5)
- Important Note about Automated DR Failover
  [https://www.vaultproject.io/guides/operations/disaster-recovery#important](https://www.vaultproject.io/guides/operations/disaster-recovery#important)

## Performance Replication

### dc1 cluster node

vault write -f sys/replication/performance/primary/enable
vault write sys/replication/performance/primary/secondary-token id="dc3"

wrapping_token: eyJhbGciOiJFUzUxMiIsInR5cCI6IkpXVCJ9....

### dc3 cluster node

vault write sys/replication/performance/secondary/enable token=<wrapping_token>

vault read sys/replication/performance/status

### Prerequisite

Terraform is already installed in local machine.

## Usage

- Clone this repository
- Setup Terraform Cloud Organisation & workspace. https://app.terraform.io/
- Change the Terraform backend accordingly in backend.tf
- Generate & setup IAM user Access & Secret Key
- Generate a AWS EC2 Key Pair in the region where you want to deploy the Vault cluster
- Create a Custom CA Cert & Key & Generate 9 sets of Certs & Keys for each of the cluster nodes. (dc1-vault1.local, dc1-vault2.local, dc1-vault3.local, ... dc3-vault3.local)
- Upload the TLS/SSL certs to a private S3 bucket.
- Add the below variable values as Terraform Variables under workspace

### terraform.tfvars

```
keypair_name = "vault-us-east-2"

s3_bucket_name = "vault-tls-certs-bucket"

vault_license = "02MV4UU43BK5HGYYTO...."

# FOR DEMO
vault_admin_password = "Password123456"

vpn_admin_password = "asdflkjhgqwerty1234"
```

- Add the below variable values as Environment Variables under workspace

```
AWS_ACCESS_KEY_ID = "access_key"

AWS_SECRET_ACCESS_KEY = "secret_key"

AWS_DEFAULT_REGION = "us-east-2"
```

- Change other variables in variables.tf file if needed
- terraform init
- terraform plan
- terraform apply -auto-approve -refresh=false
- Login to openvpn_access_server_ip with user as openvpn & vpn_admin_password
- Download the VPN connection profile
- Download & use OpenVPN client to connect to AWS VPC.
- SSH Login to centos@10.0.1.91; The Vault root token & Recovery Key is saved in files namely root_token & recovery_key respectively.
- Finally browse the Vault UI at [https://dc1-vault1.local:8200](https://dc1-vault1.local:8200)
