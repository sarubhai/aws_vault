#!/usr/bin/env bash
set -x
exec > >(tee /var/log/tf-user-data.log|logger -t user-data ) 2>&1

logger() {
  DT=$(date '+%Y/%m/%d %H:%M:%S')
  echo "$DT $0: $1"
}

logger "START"
## Install Base Prerequisites
logger "Setting timezone to UTC"
sudo timedatectl set-timezone UTC
logger "Performing updates and installing prerequisites"
sudo yum-config-manager --enable rhui-REGION-rhel-server-releases-optional
sudo yum-config-manager --enable rhui-REGION-rhel-server-supplementary
sudo yum-config-manager --enable rhui-REGION-rhel-server-extras
sudo yum -y check-update
sudo yum install -q -y wget unzip bind-utils ruby rubygems ntp
sudo yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
sudo yum -y update
sudo yum -y install jq
sudo systemctl start ntpd.service
sudo systemctl enable ntpd.service
# awscli
sudo yum -y install python3-pip
sudo yes | pip3 install awscli

## Set Hostname
sudo hostnamectl set-hostname "${vault_node_name}.local"
## Set hostnames aliases
%{ for address, name in all_node_address_names  ~}
echo "${address} ${name} ${name}.local" | sudo tee -a /etc/hosts
%{ endfor ~}
## Configure Vault user
sudo /usr/sbin/groupadd --force --system vault
sudo /usr/sbin/adduser --system --gid vault --home /srv/vault --no-create-home --shell /bin/false vault  >/dev/null

## Download Host SSL/TLS Certs
sudo mkdir -p /etc/ssl/vault
aws s3 cp s3://${s3_bucket_name}/ca.cert /etc/ssl/vault/ca.cert
aws s3 cp s3://${s3_bucket_name}/${vault_node_name}.cert /etc/ssl/vault/${vault_node_name}.cert
aws s3 cp s3://${s3_bucket_name}/${vault_node_name}.key /etc/ssl/vault/${vault_node_name}.key
sudo chown -R vault:vault /etc/ssl/vault
sudo chmod -R 0600 /etc/ssl/vault/*
# Update CA Certs
sudo cp /etc/ssl/vault/ca.cert /etc/pki/ca-trust/source/anchors/ca.cert
sudo update-ca-trust

## Install Vault
logger "Downloading Vault"
curl -o /tmp/vault.zip https://releases.hashicorp.com/vault/1.7.3+ent/vault_1.7.3+ent_linux_amd64.zip
logger "Installing Vault"
sudo unzip -o /tmp/vault.zip -d /usr/local/bin/
sudo chmod 0755 /usr/local/bin/vault
sudo chown vault:vault /usr/local/bin/vault
logger "/usr/local/bin/vault --version: $(/usr/local/bin/vault --version)"
# Create Directories
logger "Create Vault Directories"
sudo mkdir -pm 0755 /etc/vault.d

sudo mkdir -pm 0755 /vault/data
sudo chown -R vault:vault /vault/data
sudo chmod -R a+rwx /vault/data

sudo mkdir -pm 0755 /var/log/vault
sudo chown -R vault:vault /var/log/vault
sudo chmod -R a+rwx /var/log/vault

sudo mkdir -pm 0755 /etc/vault/plugin
sudo chown -R vault:vault /etc/vault/plugin
sudo chmod -R a+rwx /etc/vault/plugin

logger "Downloading Oracle Database Plugin"
curl -o /tmp/vault-plugin-database-oracle_0.4.1_linux_amd64.zip https://releases.hashicorp.com/vault-plugin-database-oracle/0.4.1/vault-plugin-database-oracle_0.4.1_linux_amd64.zip
sudo unzip -o /tmp/vault-plugin-database-oracle_0.4.1_linux_amd64.zip -d /etc/vault/plugin/
sudo chown -R vault:vault /etc/vault/plugin/vault-plugin-database-oracle
sudo chmod 0755 /etc/vault/plugin/vault-plugin-database-oracle

logger "Granting mlock syscall to vault binary"
sudo setcap cap_ipc_lock=+ep /usr/local/bin/vault
sudo setcap cap_ipc_lock=+ep /etc/vault/plugin/vault-plugin-database-oracle

## Vault Server Config
logger "Configuring Vault"
sudo tee /etc/vault.d/vault.hcl <<EOF
storage "raft" {
  path                 = "/vault/data"
  node_id              = "${vault_node_name}"
%{ for address, name in vault_node_address_names  ~}
  retry_join {
    leader_api_addr    = "https://${name}.local:8200"
  }
%{ endfor ~}
}

plugin_directory       = "/etc/vault/plugin"

listener "tcp" {
  address              = "0.0.0.0:8200"
  cluster_address      = "0.0.0.0:8201"
  tls_client_ca_file   = "/etc/ssl/vault/ca.cert"
  tls_cert_file        = "/etc/ssl/vault/${vault_node_name}.cert"
  tls_key_file         = "/etc/ssl/vault/${vault_node_name}.key"
  tls_disable          = false
}

seal "awskms" {
  kms_key_id           = "${kms_key_id}"
  region               = "${kms_region}"
}

cluster_name           = "vault-${cluster}-cluster"
api_addr               = "https://${vault_node_name}.local:8200"
cluster_addr           = "https://${vault_node_name}.local:8201"
disable_mlock          = true
ui                     = true
EOF


sudo chmod -R 0644 /etc/vault.d/*

sudo tee -a /etc/environment <<EOF
export VAULT_ADDR=https://${vault_node_name}.local:8200
export VAULT_SKIP_VERIFY=true
EOF

source /etc/environment

## Install Vault Systemd Service
read -d '' VAULT_SERVICE <<EOF
[Unit]
Description=Vault
Requires=network-online.target
After=network-online.target

[Service]
Restart=on-failure
PermissionsStartOnly=true
ExecStartPre=/sbin/setcap 'cap_ipc_lock=+ep' /usr/local/bin/vault
ExecStart=/usr/local/bin/vault server -config /etc/vault.d
ExecReload=/bin/kill -HUP \$MAINPID
KillSignal=SIGTERM
User=vault
Group=vault

[Install]
WantedBy=multi-user.target
EOF

echo "$${VAULT_SERVICE}" | sudo tee /etc/systemd/system/vault.service
sudo chmod 0664 /etc/systemd/system/vault.service

sudo systemctl enable vault
sudo systemctl start vault

## Initialize VAULT
%{ if vault_node_name == "${cluster}-vault1" }
sleep 5
logger "Initializing Vault and storing results"
vault operator init -recovery-shares 5 -recovery-threshold 3 -format=json > /tmp/key.json
sudo chown centos:centos /tmp/key.json

logger "Saving root_token and recovery key to centos user's home"
VAULT_TOKEN=$(cat /tmp/key.json | jq -r ".root_token")
echo $VAULT_TOKEN > /home/centos/root_token
sudo chown centos:centos /home/centos/root_token
echo $VAULT_TOKEN > /home/centos/.vault-token
sudo chown centos:centos /home/centos/.vault-token

echo $(cat /tmp/key.json | jq -r ".recovery_keys_b64[]") > /home/centos/recovery_key
sudo chown centos:centos /home/centos/recovery_key

logger "Setting VAULT_ADDR and VAULT_TOKEN"
export VAULT_ADDR="https://${vault_node_name}.local:8200"
export VAULT_TOKEN=$VAULT_TOKEN

logger "Waiting for Vault to finish preparations (10s)"
sleep 10

logger "Add Enterprise License"
vault write sys/license text=${vault_license}

%{ endif }

## Install Oracle Instant Client
sudo yum -y install libaio
sudo yum-config-manager --add-repo http://yum.oracle.com/repo/OracleLinux/OL7/oracle/instantclient/x86_64
sudo yum -y install oracle-instantclient19.6-basic oracle-instantclient19.6-devel oracle-instantclient19.6-sqlplus --nogpgcheck

sha256sum /etc/vault/plugin/vault-plugin-database-oracle | awk '{print $1}' >> /home/centos/sha
sudo chown centos:centos /home/centos/sha
vault write sys/plugins/catalog/database/oracle-database-plugin sha256="$(cat /home/centos/sha)" command=vault-plugin-database-oracle

# vault plugin list
# vault plugin register -sha256=0b2f3152e6f5e2e63d18db807b5d57f70c35390925ef41e07008f485b4a72bac database vault-plugin-database-oracle
# vault plugin reload -plugin vault-plugin-database-oracle
# vault plugin info database vault-plugin-database-oracle 
logger "END"
