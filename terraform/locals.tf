locals {
  resource_name = join("-", [var.project_name, var.region, var.environment, "%s"])

  public_subnet_names = { for k, v in var.subnet_settings.public : k => format(local.resource_name, v.name) }
  public_subnet_cidrs = { for k, v in var.subnet_settings.public : k => v.cidr }
  db_subnet_names     = { for k, v in var.subnet_settings.db : k => format(local.resource_name, v.name) }
  db_subnet_cidrs     = { for k, v in var.subnet_settings.db : k => v.cidr }

  param_store_prefix = format("%s/postgres-migration", var.environment)
}