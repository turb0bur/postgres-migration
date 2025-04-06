variable "project_name" {
  description = "The project name"
  type        = string
  default     = "postgres-migration"
}

variable "region" {
  description = "The AWS region"
  type        = string
}

variable "environment" {
  description = "The environment"
  type        = string
}

variable "vpc_settings" {
  description = "The common settings for the VPC"
  type = object({
    name                 = string
    cidr                 = string
    enable_dns_support   = bool
    enable_dns_hostnames = bool
  })
}

variable "subnet_settings" {
  description = "The settings for the subnets"
  type = object({
    public = map(object({
      map_public_ip_on_launch = bool
      name                    = string
      cidr                    = string
    }))
    db = map(object({
      name = string
      cidr = string
    }))
  })
}

variable "igw_settings" {
  description = "The settings for the internet gateway"
  type = object({
    name = string
  })
  default = {
    name = "main-igw"
  }
}

variable "public_route_table_settings" {
  description = "The settings for the public subnet route table"
  type = object({
    routes = map(object({
      cidr_block = string
    }))
    name = string
  })
  default = {
    routes = {
      internet = {
        cidr_block = "0.0.0.0/0"
      }
    }
    name = "public-route-table"
  }
}

variable "db_route_table_settings" {
  description = "The settings for the database subnet route table"
  type = object({
    routes = map(object({
      cidr_block = string
    }))
    name = string
  })
  default = {
    routes = {
      internet = {
        cidr_block = "0.0.0.0/0"
      }
    }
    name = "db-route-table"
  }
}

variable "bastion_host_config" {
  description = "The configuration for the Bastion instance"
  type = object({
    instance_type        = string
    template_prefix_name = string
    subnet_key           = string
    ebs_volume = object({
      size                  = number
      type                  = string
      delete_on_termination = bool
    })
  })
}

variable "bastion_host_sg_settings" {
  description = "The settings for the Bastion host security group"
  type = object({
    name = string
  })
  default = {
    name = "bastion-sg"
  }
}

variable "private_db_sg_settings" {
  description = "The settings for the security group for the private database instances"
  type = object({
    name = string
  })
  default = {
    name = "private-db-sg"
  }
}

variable "rds_instance_config" {
  description = "The configuration for the RDS instance"
  type = object({
    name                    = string
    engine                  = string
    engine_version          = string
    instance_class          = string
    parameter_group_name    = string
    allocated_storage       = number
    storage_type            = string
    publicly_accessible     = bool
    skip_final_snapshot     = bool
    multi_az                = bool
    backup_retention_period = number
    subnet_group_name       = string
  })
}

variable "rds_db_name" {
  description = "The database name"
  type        = string
  default     = "postgres"
}

variable "rds_db_user" {
  description = "The database username"
  type        = string
  default     = "postgres"
}
