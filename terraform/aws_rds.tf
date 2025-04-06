resource "aws_db_instance" "postgres_db" {
  identifier                  = format(local.resource_name, var.rds_instance_config.name)
  allocated_storage           = var.rds_instance_config.allocated_storage
  engine                      = var.rds_instance_config.engine
  engine_version              = var.rds_instance_config.engine_version
  instance_class              = var.rds_instance_config.instance_class
  parameter_group_name        = var.rds_instance_config.parameter_group_name
  skip_final_snapshot         = var.rds_instance_config.skip_final_snapshot
  publicly_accessible         = var.rds_instance_config.publicly_accessible
  multi_az                    = var.rds_instance_config.multi_az
  storage_type                = var.rds_instance_config.storage_type
  backup_retention_period     = var.rds_instance_config.backup_retention_period
  allow_major_version_upgrade = true
  vpc_security_group_ids      = [aws_security_group.rds_sg.id]
  db_subnet_group_name        = aws_db_subnet_group.postgres.name
  db_name                     = aws_ssm_parameter.postgres_db_name.value
  username                    = aws_ssm_parameter.postgres_db_user.value
  password                    = aws_ssm_parameter.postgres_db_password.value

  tags = {
    Name = format(local.resource_name, var.rds_instance_config.name)
  }
}

resource "aws_db_subnet_group" "postgres" {
  name       = var.rds_instance_config.subnet_group_name
  subnet_ids = [for subnet in aws_subnet.database : subnet.id]

  tags = {
    Name = format(local.resource_name, var.rds_instance_config.subnet_group_name)
  }
}