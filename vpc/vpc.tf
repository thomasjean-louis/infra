variable "deployment_branch" {
  type = string
}

variable "az1" {
  type = string
}

variable "az2" {
  type = string
}

variable "region" {
  type = string
}

variable "vpc_cidr_block" {
  type = string
}

variable "public_subnet_a_cidr_block" {
  type = string
}

variable "private_subnet_a_cidr_block" {
  type = string
}

variable "public_subnet_b_cidr_block" {
  type = string
}

variable "private_subnet_b_cidr_block" {
  type = string
}

resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "vpc_${var.deployment_branch}"
  }
}

output "vpc_id" {
  value = aws_vpc.vpc.id
}


resource "aws_subnet" "public_subnet_a" {
  depends_on        = [aws_vpc.vpc]
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.public_subnet_a_cidr_block
  availability_zone = var.az1

  tags = {
    Name = "public_subnet_a_${var.deployment_branch}"
  }

}

resource "aws_subnet" "private_subnet_a" {
  depends_on        = [aws_vpc.vpc]
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.private_subnet_a_cidr_block
  availability_zone = var.az1

  tags = {
    Name = "private_subnet_a_${var.deployment_branch}"
  }

}

resource "aws_subnet" "public_subnet_b" {
  depends_on        = [aws_vpc.vpc]
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.public_subnet_b_cidr_block
  availability_zone = var.az2

  tags = {
    Name = "public_subnet_b_${var.deployment_branch}"
  }

}

output "public_subnet_id_a" {
  value = aws_subnet.public_subnet_a.id
}

output "public_subnet_id_b" {
  value = aws_subnet.public_subnet_b.id
}

output "private_subnet_id_a" {
  value = aws_subnet.private_subnet_a.id
}

output "private_subnet_id_b" {
  value = aws_subnet.private_subnet_b.id
}

resource "aws_subnet" "private_subnet_b" {
  depends_on        = [aws_vpc.vpc]
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.private_subnet_b_cidr_block
  availability_zone = var.az2

  tags = {
    Name = "private_subnet_b_${var.deployment_branch}"
  }

}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_route_table" "public_route_table" {
  depends_on = [aws_vpc.vpc]
  vpc_id     = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }
}


resource "aws_route_table_association" "public_table_association_a" {
  route_table_id = aws_route_table.public_route_table.id
  subnet_id      = aws_subnet.public_subnet_a.id

}

resource "aws_route_table_association" "public_table_association_b" {
  route_table_id = aws_route_table.public_route_table.id
  subnet_id      = aws_subnet.public_subnet_b.id

}

# Private route table
resource "aws_route_table" "private_route_table" {
  depends_on = [aws_vpc.vpc]
  vpc_id     = aws_vpc.vpc.id
}

resource "aws_route_table_association" "private_table_association_a" {
  depends_on     = [aws_route_table.private_route_table, aws_subnet.private_subnet_a]
  subnet_id      = aws_subnet.private_subnet_a.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "private_table_association_b" {
  depends_on     = [aws_route_table.private_route_table, aws_subnet.private_subnet_b]
  subnet_id      = aws_subnet.private_subnet_b.id
  route_table_id = aws_route_table.private_route_table.id
}

# Create endpoints

# Endpoint Security Group
resource "aws_security_group" "sg_endpoints" {
  name   = "sg_endpoints_ecs_${var.deployment_branch}"
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_iam_policy_document" "s3_ecr_access" {
  version = "2012-10-17"
  statement {
    sid     = "s3access"
    effect  = "Allow"
    actions = ["*"]

    principals {
      type        = "*"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_vpc_endpoint" "s3_endpoint" {
  vpc_id            = aws_vpc.vpc.id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private_route_table.id]
  policy            = data.aws_iam_policy_document.s3_ecr_access.json
}

resource "aws_vpc_endpoint" "ecr_dkr_endpoint" {
  vpc_id              = aws_vpc.vpc.id
  private_dns_enabled = true
  service_name        = "com.amazonaws.${var.region}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.sg_endpoints.id]
  subnet_ids          = [aws_subnet.private_subnet_a.id, aws_subnet.private_subnet_b.id]
}

resource "aws_vpc_endpoint" "ecr_api_endpoint" {
  vpc_id              = aws_vpc.vpc.id
  service_name        = "com.amazonaws.${var.region}.ecr.api"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.sg_endpoints.id]
  subnet_ids          = [aws_subnet.private_subnet_a.id, aws_subnet.private_subnet_b.id]
}

resource "aws_vpc_endpoint" "logs_endpoint" {
  vpc_id              = aws_vpc.vpc.id
  service_name        = "com.amazonaws.${var.region}.logs"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.sg_endpoints.id]
  subnet_ids          = [aws_subnet.private_subnet_a.id, aws_subnet.private_subnet_b.id]
}

# resource "aws_eip" "eip_nat_gateway" {

# }

# resource "aws_nat_gateway" "nat_gateway" {
#   allocation_id = aws_eip.eip_nat_gateway.id
#   subnet_id     = aws_subnet.public_subnet_a.id

# }

# resource "aws_route_table" "private_route_table" {
#   depends_on = [aws_vpc.vpc]
#   vpc_id     = aws_vpc.vpc.id
#   route {
#     cidr_block     = "0.0.0.0/0"
#     nat_gateway_id = aws_nat_gateway.nat_gateway.id
#   }
# }

# resource "aws_route_table_association" "private_table_association_a" {
#   depends_on     = [aws_route_table.private_route_table, aws_subnet.private_subnet_a]
#   subnet_id      = aws_subnet.private_subnet_a.id
#   route_table_id = aws_route_table.private_route_table.id
# }

# resource "aws_route_table_association" "private_table_association_b" {
#   depends_on     = [aws_route_table.private_route_table, aws_subnet.private_subnet_b]
#   subnet_id      = aws_subnet.private_subnet_b.id
#   route_table_id = aws_route_table.private_route_table.id
# }


