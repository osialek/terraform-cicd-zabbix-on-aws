#!/bin/bash

echo "User Data Script START"

ZABBIX_RELEASE_REPO="https://repo.zabbix.com/zabbix/6.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_6.0-4+ubuntu22.04_all.deb"
ZABBIX_PACKAGE="zabbix-release_6.0-4+ubuntu22.04_all.deb"
DB_USER="zabbix"
DB_USER_PASSWORD="password"

wget ${ZABBIX_RELEASE_REPO}
sudo dpkg -i ${ZABBIX_PACKAGE}
sudo apt update
sudo apt install -y zabbix-server-mysql zabbix-frontend-php zabbix-apache-conf zabbix-sql-scripts zabbix-agent
sudo apt install -y mysql-server 

cat <<EOF > commands.sql
create database zabbix character set utf8mb4 collate utf8mb4_bin;
create user zabbix@localhost identified by '${DB_USER_PASSWORD}';
grant all privileges on zabbix.* to ${DB_USER}@localhost;
## DB User for 2nd zabbix server
set global log_bin_trust_function_creators = 1;
EOF

#execute above mysql commands on mysql server:
sudo mysql -u root < commands.sql

zcat /usr/share/zabbix-sql-scripts/mysql/server.sql.gz | mysql --default-character-set=utf8mb4 -u"$DB_USER" -p"$DB_USER_PASSWORD" zabbix
sudo mysql -u root -e "set global log_bin_trust_function_creators = 0;"
echo "DBPassword=$DB_USER_PASSWORD" | sudo tee /etc/zabbix/zabbix_server.conf -a
sudo systemctl restart zabbix-server zabbix-agent apache2
sudo systemctl enable zabbix-server zabbix-agent apache2