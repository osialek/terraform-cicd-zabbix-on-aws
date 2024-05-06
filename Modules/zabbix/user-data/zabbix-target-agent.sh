#!/bin/bash

echo "Onboarding Zabbix Agent on the machine"

ZABBIX_RELEASE_REPO="https://repo.zabbix.com/zabbix/6.4/ubuntu/pool/main/z/zabbix-release/zabbix-release_6.4-1+ubuntu22.04_all.deb"
ZABBIX_PACKAGE="zabbix-release_6.4-1+ubuntu22.04_all.deb"
#proide zabbix server/node 1 IP
ZABBIX_NODE1=${ZABBIX_NODE1}
# in case of an HA/Cluster setup. Leave "" if no HA
ZABBIX_NODE2=${ZABBIX_NODE2}


wget ${ZABBIX_RELEASE_REPO}
sudo dpkg -i ${ZABBIX_PACKAGE}
sudo apt update
sudo apt install zabbix-agent2 zabbix-agent2-plugin-*

# Replace Server IP to Zabbix Servers IPs
sudo sed -i "s/Server=127.0.0.1/Server=$ZABBIX_NODE1/g" /etc/zabbix/zabbix_agent2.conf 
# Replace ServerActive to Zabbix Servers IPs
sudo sed -i "s/ServerActive=127.0.0.1/ServerActive=$ZABBIX_NODE1/g" /etc/zabbix/zabbix_agent2.conf 
# Set target server hostname in the agent config file
sudo sed -i "s/Hostname=Zabbix server/Hostname=$HOSTNAME/g" /etc/zabbix/zabbix_agent2.conf 
sudo systemctl restart zabbix-agent2 
sudo systemctl enable zabbix-agent2








