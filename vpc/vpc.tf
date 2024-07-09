variable "az1" {
  type = string
}

variable "az2" {
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
  cidr_block = var.vpc_cidr_block
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
    Name = "public_subnet_a"
  }

}

resource "aws_subnet" "private_subnet_a" {
  depends_on        = [aws_vpc.vpc]
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.private_subnet_a_cidr_block
  availability_zone = var.az1

  tags = {
    Name = "private_subnet_a"
  }

}

resource "aws_subnet" "public_subnet_b" {
  depends_on        = [aws_vpc.vpc]
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.public_subnet_b_cidr_block
  availability_zone = var.az2

  tags = {
    Name = "public_subnet_b"
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
    Name = "private_subnet_b"
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
