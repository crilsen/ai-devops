# Recursos do módulo "network".

data "aws_availability_zones" "disponiveis" {
  state = "available"
}

locals {
  az_names = slice(data.aws_availability_zones.disponiveis.names, 0, var.az_count)
}

resource "aws_vpc" "principal" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-vpc"
  })
}

resource "aws_subnet" "publica" {
  for_each = { for idx, az in local.az_names : az => var.public_subnet_cidrs[idx] }

  vpc_id                  = aws_vpc.principal.id
  availability_zone       = each.key
  cidr_block              = each.value
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name                                        = "${var.cluster_name}-publica-${each.key}"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = "1"
  })
}

resource "aws_subnet" "privada" {
  for_each = { for idx, az in local.az_names : az => var.private_subnet_cidrs[idx] }

  vpc_id            = aws_vpc.principal.id
  availability_zone = each.key
  cidr_block        = each.value

  tags = merge(var.tags, {
    Name                                        = "${var.cluster_name}-privada-${each.key}"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = "1"
  })
}

resource "aws_internet_gateway" "principal" {
  vpc_id = aws_vpc.principal.id

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-igw"
  })
}

resource "aws_eip" "nat" {
  for_each = aws_subnet.publica

  domain = "vpc"

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-nat-${each.key}"
  })
}

resource "aws_nat_gateway" "principal" {
  for_each = aws_subnet.publica

  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = each.value.id

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-nat-${each.key}"
  })

  depends_on = [aws_internet_gateway.principal]
}

resource "aws_route_table" "publica" {
  vpc_id = aws_vpc.principal.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.principal.id
  }

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-publica"
  })
}

resource "aws_route_table_association" "publica" {
  for_each = aws_subnet.publica

  subnet_id      = each.value.id
  route_table_id = aws_route_table.publica.id
}

resource "aws_route_table" "privada" {
  for_each = aws_subnet.privada

  vpc_id = aws_vpc.principal.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.principal[each.key].id
  }

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-privada-${each.key}"
  })
}

resource "aws_route_table_association" "privada" {
  for_each = aws_subnet.privada

  subnet_id      = each.value.id
  route_table_id = aws_route_table.privada[each.key].id
}
