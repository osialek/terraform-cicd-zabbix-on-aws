terraform {
    source = "../../../Modules/zabbix/"
}
include "root" {
    path = find_in_parent_folders()
}

inputs = {
    instance_replica_count = 1
    environment = "QA"
    instance_type_zabbix_server="t3.medium"
    instance_type_bastion_host="t3.medium" #medium for better desktop performance in remote sessions.
    instance_type_workload_with_agent="t3.micro" #micro for lower costs and just demonstration of the ec2 and zabbix agent configured with user-data
}
generate "provider" {
  path = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents = <<EOF
provider "aws" {
  region = "eu-west-1"
}
EOF
}