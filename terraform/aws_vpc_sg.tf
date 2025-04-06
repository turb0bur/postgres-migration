##########################################################################################
# Security Group and Rules for Bastion Host
##########################################################################################
resource "aws_security_group" "bastion_sg" {
  vpc_id = aws_vpc.main.id
  name   = format(local.resource_name, var.bastion_host_sg_settings.name)

  tags = {
    Name = format(local.resource_name, var.bastion_host_sg_settings.name)
  }
}

resource "aws_vpc_security_group_egress_rule" "bastion_to_internet" {
  security_group_id = aws_security_group.bastion_sg.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Allow all outbound internet access"
}

##########################################################################################
# Security Group and Rules for the RDS instances
##########################################################################################
resource "aws_security_group" "rds_sg" {
  vpc_id = aws_vpc.main.id
  name   = var.private_db_sg_settings.name

  tags = {
    Name = format(local.resource_name, var.private_db_sg_settings.name)
  }
}

resource "aws_vpc_security_group_ingress_rule" "bastion_host_to_db" {
  security_group_id            = aws_security_group.rds_sg.id
  referenced_security_group_id = aws_security_group.bastion_sg.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  description                  = "Allow connections from Bastion Host"
}

resource "aws_vpc_security_group_egress_rule" "default_rds" {
  security_group_id = aws_security_group.rds_sg.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}