# + number of web server instances (according to environment) and one db server
# + Security groups + NACLs + Route Tables

# AMI used by Web & Database servers
data "aws_ami" "ubuntu_2204_latest" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  owners = ["099720109477"] # <-- Canonical
}

# Fetch current Region
data "aws_region" "current" {}

locals {
  region = data.aws_region.current.name
}


# Web Server security group with dynamic rules association from object variable
resource "aws_security_group" "sg_zabbix_server" {
  name   = "sg_zabbix_server"
  vpc_id = aws_vpc.core_vpc.id
  dynamic "ingress" {
    for_each = var.zabbix_server_sg_ingress_rules
    content {
      description = ingress.value.description
      from_port   = ingress.value.port
      to_port     = ingress.value.port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }
  ingress {
    description     = "SSH from Bastion Host only"
    from_port       = "22"
    to_port         = "22"
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_bastion_host.id]
  }
  dynamic "egress" {
    for_each = var.zabbix_server_sg_egress_rules
    content {
      description = egress.value.description
      from_port   = egress.value.port
      to_port     = egress.value.port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
    }
  }
  lifecycle {
    create_before_destroy = true
    # prevent_destroy = true
  }
  tags = {
    Name        = "sg-zabbix-server"
    Service     = var.app_identifier
    Terraform   = "true"
    Environment = var.environment
  }
}
resource "aws_security_group" "sg_bastion_host" {
  name   = "sg_bastion_host"
  vpc_id = aws_vpc.core_vpc.id
  tags = {
    Name        = "sg-bastion-host"
    Terraform   = "true"
    Environment = "${var.environment}"
  }
  dynamic "ingress" {
    for_each = var.bastion_host_sg_ingress_rules
    content {
      description = ingress.value.description
      from_port   = ingress.value.port
      to_port     = ingress.value.port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }
  egress {
    description = "Access to internet - egress only (stateful)"
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  lifecycle {
    create_before_destroy = true
  }
}

module "ssm_instance_profile" {
  source  = "bayupw/ssm-instance-profile/aws"
  version = "1.1.0"
}

resource "aws_instance" "bastion_host" {
  ami                         = var.bastion_host_ami
  instance_type               = var.instance_type_zabbix_server
  subnet_id                   = aws_subnet.public_subnet01.id
  iam_instance_profile        = module.ssm_instance_profile.aws_iam_instance_profile
  key_name                    = aws_key_pair.generated.key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.sg_bastion_host.id]
  tags = {
    Name        = "${var.environment}-${var.app_identifier}-bastion-host"
    Terraform   = "true"
    Service     = var.app_identifier
    Environment = var.environment
  }
}
# Create EIP for Bastion Host
resource "aws_eip" "bastion_host" {
  domain   = "vpc"
  instance = aws_instance.bastion_host.id
  tags = {
    Name        = "${aws_vpc.core_vpc.tags.Name}-bastion-host-eip"
    Terraform   = "true"
    Environment = "${var.environment}"
  }
}
# Deploy EC2 for Zabbix Server with user-data script execution
resource "aws_instance" "zabbix_server_1" {
  ami                         = data.aws_ami.ubuntu_2204_latest.id
  instance_type               = var.instance_type_zabbix_server
  subnet_id                   = aws_subnet.private_subnet01.id
  iam_instance_profile        = module.ssm_instance_profile.aws_iam_instance_profile
  key_name                    = aws_key_pair.generated.key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.sg_zabbix_server.id]
  user_data                   = file("./user-data/zabbix-user-data.sh")
  tags = {
    Name        = "${var.environment}-${var.app_identifier}-server-1"
    Terraform   = "true"
    Service     = var.app_identifier
    Environment = var.environment
  }
}
# Create EIP for EC2 Instance ZabbixServer
resource "aws_eip" "zabbix_server_1" {
  domain   = "vpc"
  instance = aws_instance.zabbix_server_1.id
  tags = {
    Name        = "${aws_vpc.core_vpc.tags.Name}-zabbix-server-eip"
    Terraform   = "true"
    Environment = "${var.environment}"
  }
}
output "zabbix_node_1_public_ip" {
  value = aws_instance.zabbix_server_1.public_ip
}
output "zabbix_node_1_private_ip" {
  value = aws_instance.zabbix_server_1.private_ip
}

# Use in case of HA setup (with subnets in >= 2 AZs)
# \/\/\/\/
# resource "aws_instance" "zabbix_server_2" {
#   ami           = data.aws_ami.ubuntu_2204_latest.id
#   instance_type = var.instance_type_zabbix_server
#   subnet_id                   = aws_subnet.public_subnet01.id
#   iam_instance_profile = module.ssm_instance_profile.aws_iam_instance_profile
#   key_name = aws_key_pair.generated.key_name
#   associate_public_ip_address = true
#   security_groups             = [aws_security_group.sg_zabbix_server.id]
#   user_data                   = file("./user-data/zabbix-user-data.sh")
#   tags = {
#     Name        = "${var.environment}-${var.app_identifier}-server-2"
#     Terraform   = "true"
#     Service     = var.app_identifier
#     Environment = var.environment
#   }
# }

# # Create EIP for EC2 Instance ZabbixServer
# resource "aws_eip" "zabbix_node_2" {
#   # count = var.instance_replica_count
#   domain   = "vpc"
#   instance = aws_instance.zabbix_node_2.id
#   tags = {
#     Name        = "${aws_vpc.core_vpc.tags.Name}-zabbix-node-2-eip"
#     Terraform   = "true"
#     Environment = "${var.environment}"
#   }
# }

# example host with zabbix agent
resource "aws_instance" "ec2_zabbix_agent" {
  ami           = data.aws_ami.ubuntu_2204_latest.id
  instance_type = var.instance_type_workload_with_agent
  depends_on    = [aws_instance.zabbix_server_1]
  # count                       = var.instance_replica_count
  subnet_id                   = aws_subnet.public_subnet01.id
  iam_instance_profile        = module.ssm_instance_profile.aws_iam_instance_profile
  key_name                    = aws_key_pair.generated.key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.sg_zabbix_server.id]
  user_data = base64encode(templatefile("./user-data/zabbix-target-agent.sh", {
    ZABBIX_RELEASE_REPO = "https://repo.zabbix.com/zabbix/6.4/ubuntu/pool/main/z/zabbix-release/zabbix-release_6.4-1+ubuntu22.04_all.deb"
    ZABBIX_PACKAGE      = "zabbix-release_6.4-1+ubuntu22.04_all.deb"
    ZABBIX_NODE1        = aws_instance.zabbix_server_1.private_ip
    ZABBIX_NODE2        = aws_instance.zabbix_server_1.private_ip
  }))
  tags = {
    Name        = "${var.environment}-${var.app_identifier}-random-ec2-with-zabbix-agent"
    Terraform   = "true"
    Service     = var.app_identifier
    Environment = var.environment
  }

}
###### SSH KEY PAIR FOR ACCESING THE EC2 INSTANCES #####
resource "tls_private_key" "generated" {
  algorithm = "RSA"
}
resource "local_file" "private_key_pem" {
  content  = tls_private_key.generated.private_key_pem
  filename = "ec2_SSH_Key.pem"
}
resource "aws_key_pair" "generated" {
  key_name   = "ec2_SSH_Key"
  public_key = tls_private_key.generated.public_key_openssh
  lifecycle {
    ignore_changes = [key_name]
  }
}