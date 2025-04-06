resource "aws_vpc" "main" {
  cidr_block           = var.vpc_settings.cidr
  enable_dns_support   = var.vpc_settings.enable_dns_support
  enable_dns_hostnames = var.vpc_settings.enable_dns_hostnames

  tags = {
    Name = format(local.resource_name, var.vpc_settings.name)
  }
}

resource "aws_subnet" "public" {
  for_each          = var.subnet_settings.public
  vpc_id            = aws_vpc.main.id
  cidr_block        = local.public_subnet_cidrs[each.key]
  availability_zone = element(data.aws_availability_zones.available.names, index(keys(var.subnet_settings.public), each.key))

  map_public_ip_on_launch = each.value.map_public_ip_on_launch

  tags = {
    Name = local.public_subnet_names[each.key]
  }
}

resource "aws_subnet" "database" {
  for_each          = var.subnet_settings.db
  vpc_id            = aws_vpc.main.id
  cidr_block        = local.db_subnet_cidrs[each.key]
  availability_zone = element(data.aws_availability_zones.available.names, index(keys(var.subnet_settings.db), each.key))

  tags = {
    Name = local.db_subnet_names[each.key]
  }
}

resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = format(local.resource_name, var.igw_settings.name)
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = var.public_route_table_settings.routes.internet.cidr_block
    gateway_id = aws_internet_gateway.main_igw.id
  }

  tags = {
    Name = format(local.resource_name, var.public_route_table_settings.name)
  }
}

resource "aws_route_table" "database" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = format(local.resource_name, var.db_route_table_settings.name)
  }
}

resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "database" {
  for_each       = aws_subnet.database
  subnet_id      = each.value.id
  route_table_id = aws_route_table.database.id
}
