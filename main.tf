# VPC
resource "aws_vpc" "dev_vpc" {

  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    "Name" = "dev-vpc"
  }
}

# Subnet - public subnet
resource "aws_subnet" "public_subnet1" {

  vpc_id                  = aws_vpc.dev_vpc.id
  cidr_block              = "10.0.0.0/20"
  availability_zone       = "ap-northeast-1a"
  map_public_ip_on_launch = true

  tags = {
    "Name" = "public-subnet-1a"
  }

}

# Subnet - private subnet
resource "aws_subnet" "private_subnet1" {

  vpc_id            = aws_vpc.dev_vpc.id
  cidr_block        = "10.0.16.0/20"
  availability_zone = "ap-northeast-1a"

  tags = {
    "Name" = "private-subnet-1a"
  }

}

# Internet Gateway
resource "aws_internet_gateway" "igw_dev_vpc" {

  vpc_id = aws_vpc.dev_vpc.id

  tags = {
    "Name" = "igw-dev-vpc"
  }

}

# Route table for public subnet
resource "aws_route_table" "public_route_table" {

  vpc_id = aws_vpc.dev_vpc.id

  tags = {
    "Name" = "public-rt-1"
  }

}

# Route configuration for public subnet
resource "aws_route" "public_route_table_route" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw_dev_vpc.id
}

# Associate public subnet with route-table
resource "aws_route_table_association" "public_route_table_association" {
  subnet_id      = aws_subnet.public_subnet1.id
  route_table_id = aws_route_table.public_route_table.id

}

# Elstic IP and Nat Gateway

resource "aws_eip" "eip" {
  vpc = true
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.public_subnet1.id

  tags = {
    "Name" = "nat-gw"
  }

}


# Route table for private subnet
resource "aws_route_table" "private_route_table" {

  vpc_id = aws_vpc.dev_vpc.id

  tags = {
    "Name" = "private-rt-1"
  }

}


# Add nat gateway with private subnet route
resource "aws_route" "private_route_table_route" {
  route_table_id         = aws_route_table.private_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_nat_gateway.nat_gateway.id
}

# Associate private subnet with route-table
resource "aws_route_table_association" "private_route_table_association" {
  subnet_id      = aws_subnet.private_subnet1.id
  route_table_id = aws_route_table.private_route_table.id

}


# security group - public access
resource "aws_security_group" "public_access" {

  name        = "public_access"
  description = "Allow inbound traffic"
  vpc_id      = aws_vpc.dev_vpc.id

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    description = "allow public access"
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

# ssh and ping access from public subnet
resource "aws_security_group" "ssh_ping_access" {

  name        = "ssh_ping_access"
  description = "Allow ssh and ping traffic"
  vpc_id      = aws_vpc.dev_vpc.id

  ingress {
    description     = "allow ssh access"
    from_port       = 22
    protocol        = "tcp"
    to_port         = 22
    security_groups = [aws_security_group.public_access.id] # from this security group
  }
  ingress {
    description     = "allow ping access"
    from_port       = -1
    protocol        = "icmp"
    to_port         = -1
    security_groups = [aws_security_group.public_access.id] # from this security group
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}


# key_pair create
resource "aws_key_pair" "access_key" {
  key_name   = "aws_access"
  public_key = file("~/.ssh/aws_access.pub")
}


# Public Instance  - Baston host
resource "aws_instance" "baston_host" {

  instance_type          = "t2.micro"
  ami                    = data.aws_ami.server_ami.id
  key_name               = aws_key_pair.access_key.id
  vpc_security_group_ids = [aws_security_group.public_access.id]
  subnet_id              = aws_subnet.public_subnet1.id
  user_data              = file("userdata.tpl")

  root_block_device {
    volume_size = 10
  }

  tags = {
    "Name" = "baston-host"
  }

  provisioner "local-exec" {
    command = templatefile("ssh-config.tpl", {
      hostname     = self.public_ip,
      user         = "ec2-user"
      identityfile = "~/.ssh/aws_access"
    })
    interpreter = [
      "bash",
      "-c"
    ]
  }

}

# Private Instance 
resource "aws_instance" "private_node" {

  instance_type          = "t2.micro"
  ami                    = data.aws_ami.server_ami.id
  key_name               = aws_key_pair.access_key.id
  vpc_security_group_ids = [aws_security_group.ssh_ping_access.id]
  subnet_id              = aws_subnet.private_subnet1.id

  root_block_device {
    volume_size = 10
  }

  tags = {
    "Name" = "private-node"
  }

}




