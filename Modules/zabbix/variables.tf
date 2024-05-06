# SECURITY GROUP RULES:
#######################
# Zabbix Server:
variable "zabbix_server_sg_ingress_rules" {
  type = map(object(
    {
      description = string
      port        = number
      protocol    = string
      cidr_blocks = list(string)
    }
  ))
  default = {
    "80" = {
      description = "Port 80 = HTTP"
      port        = 80
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/16"]
    }
    "443" = {
      description = "Port 443 = HTTPS"
      port        = 443
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/16"]
    }
    "10051" = {
      description = "Port 10051 - Server/Active Proxy/Passive Proxy"
      port        = 10051
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/16"]
    }
    "10050" = {
      description = "Port 10050 - Agent2"
      port        = 10050
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/16"]
    }
    "10053" = {
      description = "Port 10053 - JavaGateway/WebService"
      port        = 10053
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/16"]
    }
    # "all" = {
    #   description = "All internal"
    #   port        = 0
    #   protocol    = "-1"
    #   cidr_blocks = ["10.0.0.0/16"]
    # }
  }
}
variable "zabbix_server_sg_egress_rules" {
  type = map(object(
    {
      description = string
      port        = number
      protocol    = string
      cidr_blocks = list(string)
    }
  ))
  default = {
    "internet" = {
      description = "Access to internet - egress only (stateful)"
      port        = "0"
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}
# SECURITY GROUP RULES:
#######################
# Bastin Host:
variable "bastion_host_sg_ingress_rules" {
  type = map(object(
    {
      description = string
      port        = number
      protocol    = string
      cidr_blocks = list(string)
    }
  ))
  default = {
    "22" = {
      description = "Port 22 = SSH"
      port        = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
    "3389" = {
      description = "Port 3389 = RDP"
      port        = 3389
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
    "all" = {
      description = "All internal"
      port        = 0
      protocol    = "-1"
      cidr_blocks = ["10.0.0.0/16"]
    }
  }
}

## Common NACL rules (private & public)
variable "common_nacl_ingress_rules" {
  type = map(object(
    {
      protocol   = string
      rule_no    = number
      action     = string
      cidr_block = string
      from_port  = number
      to_port    = number
    }
  ))
  default = {
    # Allow IN traffic for user/server applications & clients    
    "ephemeral ports" = {
      protocol   = "tcp"
      rule_no    = 100
      action     = "allow"
      cidr_block = "0.0.0.0/0"
      from_port  = 1024
      to_port    = 65535
    }
    # Allow IN all traffic from AWS internal network
    "internal_network" = {
      protocol   = "-1"
      rule_no    = 101
      action     = "allow"
      cidr_block = "10.0.0.0/16"
      from_port  = 0
      to_port    = 0
    }
  }
}
variable "common_nacl_egress_rules" {
  type = map(object(
    {
      protocol   = string
      rule_no    = number
      action     = string
      cidr_block = string
      from_port  = number
      to_port    = number
    }
  ))
  default = {
    "allow_all" = {
      protocol   = "-1"
      rule_no    = 200
      action     = "allow"
      cidr_block = "0.0.0.0/0"
      from_port  = 0
      to_port    = 0
    }
  }
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}
variable "private_subnet_cidr" {
  type    = string
  default = "10.0.0.0/24"
}
variable "public_subnet_cidr" {
  type    = string
  default = "10.0.100.0/24"
}
variable "zone_ids" {
  type    = list(string)
  default = ["euc1-az1", "euc1-az2", "euc1-az3"]
}
variable "environment" {
  type = string
}
variable "app_identifier" {
  type    = string
  default = "zabbix"
}
variable "instance_type_zabbix_server" {
  type = string
}
variable "instance_type_workload_with_agent" {
  type = string
}
variable "instance_type_bastion_host" {
  type = string
}
variable "bastion_host_ami" {
  type    = string
  default = "ami-0847a7983fdc60e79"
}