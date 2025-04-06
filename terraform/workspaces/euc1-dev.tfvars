region      = "eu-central-1"
environment = "dev"

vpc_settings = {
  name                 = "main-vpc"
  cidr                 = "10.20.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

subnet_settings = {
  public = {
    subnet1 = {
      map_public_ip_on_launch = true
      name                    = "public-subnet-1"
      cidr                    = "10.20.1.0/24"
    }
    subnet2 = {
      map_public_ip_on_launch = true
      name                    = "public-subnet-2"
      cidr                    = "10.20.2.0/24"
    }
  }

  db = {
    subnet1 = {
      name = "db-subnet-1"
      cidr = "10.20.30.0/24"
    }
    subnet2 = {
      name = "db-subnet-2"
      cidr = "10.20.40.0/24"
    }
  }
}

bastion_host_config = {
  instance_type        = "t3.micro"
  template_prefix_name = "bastion-instance-"
  subnet_key           = "subnet1"
  ebs_volume = {
    size                  = 8
    type                  = "gp3"
    delete_on_termination = true
  }
}

rds_instance_config = {
  name                    = "postgres-db"
  engine                  = "postgres"
  engine_version          = "17"
  instance_class          = "db.t3.small"
  parameter_group_name    = "default.postgres17"
  allocated_storage       = 20
  storage_type            = "gp3"
  publicly_accessible     = false
  skip_final_snapshot     = true
  multi_az                = true
  backup_retention_period = 7
  subnet_group_name       = "postgres-db-subnet-group"
}