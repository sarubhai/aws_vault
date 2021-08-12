#!/bin/bash
# Name: database_server.sh
# Owner: Saurav Mitra
# Description: Configure containerized database server for demo

# Install Docker, Docker-compose
sudo yum -y update
sudo yum -y install yum-utils
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum -y update
sudo yum -y install docker-ce docker-ce-cli containerd.io
sudo systemctl start docker
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-Linux-x86_64" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose


# Install Oracle Instant Client
cd /root
curl -L -s https://download.oracle.com/otn_software/linux/instantclient/211000/oracle-instantclient-basic-21.1.0.0.0-1.x86_64.rpm -o oracle-instantclient-basic-21.1.0.0.0-1.x86_64.rpm
curl -L -s https://download.oracle.com/otn_software/linux/instantclient/211000/oracle-instantclient-sqlplus-21.1.0.0.0-1.x86_64.rpm -o oracle-instantclient-sqlplus-21.1.0.0.0-1.x86_64.rpm
sudo yum -y install libaio
sudo rpm -ivh oracle-instantclient-basic-21.1.0.0.0-1.x86_64.rpm
sudo rpm -ivh oracle-instantclient-sqlplus-21.1.0.0.0-1.x86_64.rpm
rm -rf /root/oracle-instantclient-basic-21.1.0.0.0-1.x86_64.rpm
rm -rf /root/oracle-instantclient-sqlplus-21.1.0.0.0-1.x86_64.rpm

echo 'ORACLE_HOME=/usr/lib/oracle/21/client64' >> ~/.bash_profile 
echo 'PATH=$ORACLE_HOME/bin:$PATH' >> ~/.bash_profile
echo 'LD_LIBRARY_PATH=$ORACLE_HOME/lib' >> ~/.bash_profile
echo 'export ORACLE_HOME' >> ~/.bash_profile
echo 'export LD_LIBRARY_PATH' >> ~/.bash_profile
echo 'export PATH' >> ~/.bash_profile
source ~/.bash_profile


# Build Oracle 11g Image (oracle/database:11.2.0.2-xe)
cd /root
sudo yum -y install git
git clone https://github.com/oracle/docker-images.git
cd /root/docker-images/OracleDatabase/SingleInstance/dockerfiles/11.2.0.2
curl https://ashnik-confluent-oracle-demo.s3-us-west-2.amazonaws.com/oracle-xe-11.2.0-1.0.x86_64.rpm.zip -o oracle-xe-11.2.0-1.0.x86_64.rpm.zip
cd /root/docker-images/OracleDatabase/SingleInstance/dockerfiles
./buildContainerImage.sh -x -v 11.2.0.2 -o "--memory=1g --memory-swap=2g"


# Spawn Oracle Source Container
mkdir /root/oracle_src
cd /root/oracle_src
sudo tee /root/oracle_src/docker-compose.yml &>/dev/null <<EOF
version: "3"
services:
  oracle_src:
    image: oracle/database:11.2.0.2-xe
    shm_size: 1gb
    ports:
      - "1521:1521"
    environment:
      - ORACLE_PWD=${vault_admin_password}
EOF

docker-compose up -d

# Initial Database Setup
# Oracle XE 11g Source
while [ "`docker inspect -f {{.State.Health.Status}} oracle_src_oracle_src_1`" != "healthy" ]; do
  sleep 60;
done;
# SYSDBA
sqlplus -s /nolog <<EOF >${vault_admin_password}
connect sys/${vault_admin_password}@(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=127.0.0.1)(PORT=1521))(CONNECT_DATA=(SID=XE))) as sysdba
alter user hr account unlock identified by hr;
create user orcl_user identified by ${vault_admin_password};
grant DBA to orcl_user;
create table orcl_user.EMPLOYEES as select * from hr.EMPLOYEES;
create table orcl_user.DEPARTMENTS as select * from hr.DEPARTMENTS;
create table orcl_user.JOBS as select * from hr.JOBS;
create table orcl_user.JOB_HISTORY as select * from hr.JOB_HISTORY;
create table orcl_user.COUNTRIES as select * from hr.COUNTRIES;
create table orcl_user.REGIONS as select * from hr.REGIONS;
create table orcl_user.LOCATIONS as select * from hr.LOCATIONS;
alter database ADD SUPPLEMENTAL LOG DATA;
alter database ADD SUPPLEMENTAL LOG DATA (ALL) COLUMNS;
quit
EOF


# Install MySQL Client
sudo yum -y install mysql
# Spawn MySQL/MaraiDB Container
mkdir /root/mariadb
cd /root/mariadb
sudo tee /root/mariadb/docker-compose.yml &>/dev/null <<EOF
version: "3.1"
services:
  mariadb:
    image: mariadb:latest
    ports:
      - 3306:3306
    environment:
      MYSQL_ROOT_HOST: '%'
      MYSQL_ROOT_PASSWORD: ${vault_admin_password}
    command:
    - --log-bin=binlog
    - --binlog-format=ROW
    - --server-id=1
    - --sql_mode=
EOF

docker-compose up -d
# MySQL Source Database
sleep 30;

curl -L https://s3-ap-southeast-1.amazonaws.com/dwbi-datalake/dataset/showroom.sql -o showroom.sql
curl -L https://s3-ap-southeast-1.amazonaws.com/dwbi-datalake/dataset/customer.sql -o customer.sql
curl -L https://s3-ap-southeast-1.amazonaws.com/dwbi-datalake/dataset/product.sql -o product.sql
curl -L https://s3-ap-southeast-1.amazonaws.com/dwbi-datalake/dataset/sales.sql -o sales.sql
curl -L https://s3-ap-southeast-1.amazonaws.com/dwbi-datalake/dataset/stocks.sql -o stocks.sql

mysql --host=127.0.0.1 --port=3306 --user root -p${vault_admin_password} -e "create database sales;"
mysql --host=127.0.0.1 --port=3306 --user root -p${vault_admin_password} sales < /root/mariadb/showroom.sql
mysql --host=127.0.0.1 --port=3306 --user root -p${vault_admin_password} sales < /root/mariadb/customer.sql
mysql --host=127.0.0.1 --port=3306 --user root -p${vault_admin_password} sales < /root/mariadb/product.sql
mysql --host=127.0.0.1 --port=3306 --user root -p${vault_admin_password} sales < /root/mariadb/sales.sql
mysql --host=127.0.0.1 --port=3306 --user root -p${vault_admin_password} sales < /root/mariadb/stocks.sql

mysql --host=127.0.0.1 --port=3306 --user root -p${vault_admin_password} -e "alter table showroom modify column id int auto_increment primary key;" sales
mysql --host=127.0.0.1 --port=3306 --user root -p${vault_admin_password} -e "alter table customer modify column id int auto_increment primary key;" sales
mysql --host=127.0.0.1 --port=3306 --user root -p${vault_admin_password} -e "alter table product modify column id int auto_increment primary key;" sales
mysql --host=127.0.0.1 --port=3306 --user root -p${vault_admin_password} -e "alter table stocks modify column id int auto_increment primary key;" sales


# Install PostgreSQL Client
sudo yum -y install postgresql
# Spawn PostgreSQL Container
mkdir /root/postgres
cd /root/postgres
sudo tee /root/postgres/docker-compose.yml &>/dev/null <<EOF
version: "3.1"
services:
  postgres:
    image: postgres:latest
    ports:
      - 5432:5432
    environment:
      POSTGRES_PASSWORD: ${vault_admin_password}
    command:
      - "postgres"
      - "-c"
      - "wal_level=logical"
EOF

docker-compose up -d
# PostgreSQL Database
echo "PGPASSWORD=${vault_admin_password}" >> ~/.bash_profile 
echo 'export PGPASSWORD' >> ~/.bash_profile
source ~/.bash_profile


# Spawn Elasticsearch Container
mkdir /root/elk
cd /root/elk
sudo tee /root/elk/docker-compose.yml &>/dev/null <<EOF
version: "3"
services:
  elasticsearch:
    image: elasticsearch:7.13.1
    ports:
      - 9200:9200
    environment:
      - bootstrap.memory_lock=true
      - discovery.type=single-node
      - "ES_JAVA_OPTS=-Xms2g -Xmx2g"
      - ELASTIC_PASSWORD=${vault_admin_password}
      - xpack.security.enabled=true
    ulimits:
      memlock:
        soft: -1
        hard: -1
    networks: ['elk']
  kibana:
    image: kibana:7.13.1
    ports: ['5601:5601']
    environment:
      - ELASTICSEARCH_USERNAME=elastic
      - ELASTICSEARCH_PASSWORD=${vault_admin_password}
    networks: ['elk']
    links: ['elasticsearch']
    depends_on: ['elasticsearch']
networks:
  elk: {}
EOF

docker-compose up -d


# Install MongoDB Client
echo "[mongodb-org-4.4]" > /etc/yum.repos.d/mongodb-org-4.4.repo
echo "name=MongoDB Repository" >> /etc/yum.repos.d/mongodb-org-4.4.repo
echo 'baseurl=https://repo.mongodb.org/yum/redhat/$releasever/mongodb-org/4.4/x86_64/' >> /etc/yum.repos.d/mongodb-org-4.4.repo
echo "gpgcheck=1" >> /etc/yum.repos.d/mongodb-org-4.4.repo
echo "enabled=1" >> /etc/yum.repos.d/mongodb-org-4.4.repo
echo "gpgkey=https://www.mongodb.org/static/pgp/server-4.4.asc" >> /etc/yum.repos.d/mongodb-org-4.4.repo
sudo yum -y install mongodb-org-shell-4.4.2
# Spawn MongoDB Container
mkdir /root/mongodb
cd /root/mongodb
sudo tee /root/mongodb/docker-compose.yml &>/dev/null <<EOF
version: "3.1"
services:
  mongo:
    image: mongo
    ports:
      - 27017:27017
    environment:
      MONGO_INITDB_ROOT_USERNAME: root
      MONGO_INITDB_ROOT_PASSWORD: ${vault_admin_password}
EOF

docker-compose up -d


# Spawn OpenLDAP Container
mkdir /root/openldap
cd /root/openldap
sudo tee /root/openldap/bootstrap.ldif &>/dev/null <<EOF
dn: cn=developer,dc=example,dc=com
changetype: add
objectclass: inetOrgPerson
cn: developer
givenname: developer
sn: Developer
displayname: Developer User
mail: developer@example.com
userpassword: Password1234

dn: cn=tester,dc=example,dc=com
changetype: add
objectclass: inetOrgPerson
cn: tester
givenname: tester
sn: Tester
displayname: Tester User
mail: tester@example.com
userpassword: Password1234

dn: cn=manager,dc=example,dc=com
changetype: add
objectclass: inetOrgPerson
cn: manager
givenname: manager
sn: Manager
displayname: Manager User
mail: manager@example.com
userpassword: Password1234

dn: cn=admin,dc=example,dc=com
changetype: add
objectclass: inetOrgPerson
cn: admin
givenname: admin
sn: Administrator
displayname: Admin User
mail: admin@example.com
userpassword: ${vault_admin_password}

dn: ou=Users,dc=example,dc=com
changetype: add
objectclass: organizationalUnit
ou: Users

dn: ou=Groups,dc=example,dc=com
changetype: add
objectclass: organizationalUnit
ou: Groups

dn: cn=Admins,ou=Groups,dc=example,dc=com
changetype: add
cn: Admins
objectclass: groupOfUniqueNames
uniqueMember: cn=admin,dc=example,dc=com

dn: cn=DevTeam,ou=Groups,dc=example,dc=com
changetype: add
cn: DevTeam
objectclass: groupOfUniqueNames
uniqueMember: cn=developer,dc=example,dc=com
uniqueMember: cn=tester,dc=example,dc=com
EOF

sudo tee /root/openldap/Dockerfile &>/dev/null <<EOF
FROM osixia/openldap
LABEL maintainer="saurav.karate@gmail.com"
ENV LDAP_ORGANISATION="Example Com" LDAP_DOMAIN="example.com"
COPY bootstrap.ldif /container/service/slapd/assets/config/bootstrap/ldif/50-bootstrap.ldif
EOF

docker build -t openldap-with-data .

sudo tee /root/openldap/docker-compose.yml &>/dev/null <<EOF
version: "3.1"
services:
  ldap_server:
    image: openldap-with-data
    container_name: "ldap_server"
    ports:
      - 389:389
    environment:
      LDAP_BASE_DN: dc=example,dc=com
      LDAP_ADMIN_PASSWORD: ${vault_admin_password}

  ldap_server_admin:
    image: osixia/phpldapadmin
    container_name: "ldap_server_admin"
    ports:
      - 80:80
    environment:
      PHPLDAPADMIN_LDAP_HOSTS: ldap_server
      PHPLDAPADMIN_HTTPS: "false" 
EOF

docker-compose up -d


# Spawn RabbitMQ Container
mkdir /root/rabbitmq
cd /root/rabbitmq
sudo tee /root/rabbitmq/docker-compose.yml &>/dev/null <<EOF
version: "3.1"
services:
  rabbitmq:
    image: rabbitmq:3.8-management
    container_name: "rabbitmq"
    ports:
      - 5672:5672
      - 15672:15672
    environment:
      RABBITMQ_DEFAULT_USER: rabbitmq
      RABBITMQ_DEFAULT_PASS: ${vault_admin_password}
EOF

docker-compose up -d
