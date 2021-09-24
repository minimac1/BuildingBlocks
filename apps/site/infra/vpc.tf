# Deploying a VPC for each site is unnecessary
# Eventually convert this to a shared resource and
# allocate sites their subnets
resource "aws_vpc" "main" {
  cidr_block       = "1.0.0.0/16"
  instance_tenancy = "default"

  tags = merge(local.tags, {
    service = "vpc"
  })
}

resource "aws_subnet" "subnet_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "1.0.0.0/24"
  availability_zone = "ap-southeast-2a"

  tags = merge(local.tags, {
    service = "subnet"
  })
}

resource "aws_subnet" "subnet_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "1.0.1.0/24"
  availability_zone = "ap-southeast-2b"

  tags = merge(local.tags, {
    service = "subnet"
  })
}

resource "aws_subnet" "subnet_c" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "1.0.2.0/24"
  availability_zone = "ap-southeast-2c"

  tags = merge(local.tags, {
    service = "subnet"
  })
}

resource "aws_route_table" "main_route_table" {
  vpc_id = aws_vpc.main.id
  tags = merge(local.tags, {
    service = "route_table"
  })
}

resource "aws_route_table_association" "rta_a" {
  subnet_id      = aws_subnet.subnet_a.id
  route_table_id = aws_route_table.main_route_table.id
}

resource "aws_internet_gateway" "main_gw" {
  tags = merge(local.tags, {
    service = "main_gw"
  })
  vpc_id     = aws_vpc.main.id
  depends_on = [aws_vpc.main]
}

resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.main_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main_gw.id
}

resource "aws_security_group" "allow_tls" {
  depends_on  = [aws_vpc.main]
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  ingress {
    description      = "Web inbound traffic"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description      = "all outbound"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }


  tags = merge(local.tags, {
    service = "security_group"
  })
}

resource "tls_private_key" "web_key" {
  algorithm = "RSA"
}

resource "aws_key_pair" "app_instance_key" {
  key_name   = "web_key"
  public_key = tls_private_key.web_key.public_key_openssh
}

resource "local_file" "web_key" {
  content  = tls_private_key.web_key.private_key_pem
  filename = "web_key.pem"
}