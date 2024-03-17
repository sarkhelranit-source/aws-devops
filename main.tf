provider "aws" {
  region     = "us-west-1"
  access_key = "get-it-from-security-credentials"
  secret_key = "get-it-from-security-credentials"
}

# 1. Create a VPC
resource "aws_vpc" "my-custom-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    "Name" = "my-custom-vpc"
  }
}

# 2. Create an Internet Gateway
resource "aws_internet_gateway" "my-custom-igw" {
  vpc_id = aws_vpc.my-custom-vpc.id
  tags = {
    "Name" = "my-custom-igw"
  }
}

# 3. Create a Custom Route Table
resource "aws_route_table" "my-custom-rt" {
  vpc_id = aws_vpc.my-custom-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my-custom-igw.id
  }
  tags = {
    "Name" = "my-custom-rt"
  }
}

# 4. Create a Subnet
resource "aws_subnet" "public-subnet" {
  vpc_id            = aws_vpc.my-custom-vpc.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "us-west-1a"
  tags = {
    "Name" = "public-subnet"
  }
}

# 5. Associate the Subnet with Route Table
resource "aws_route_table_association" "rt-with-public-subnet" {
  subnet_id      = aws_subnet.public-subnet.id
  route_table_id = aws_route_table.my-custom-rt.id
}

# 6. Create a Security Group to allow all traffic
resource "aws_security_group" "my-new-sg" {
  vpc_id      = aws_vpc.my-custom-vpc.id
  name        = "allow"
  description = "Allow All Traffic"

  tags = {
    "Name" = "my-new-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_all" {
  security_group_id = aws_security_group.my-new-sg.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "allow_all" {
  security_group_id = aws_security_group.my-new-sg.id
  ip_protocol = "-1"
  cidr_ipv4 = "0.0.0.0/0"
}

# 7. Create a Key-Pair and a Ubuntu Server and install/update apache2
resource "aws_instance" "ubuntu-server" {
  ami                    = "ami-05c969369880fa2c2"
  instance_type          = "t2.micro"
  availability_zone      = "us-west-1a"
  vpc_security_group_ids = [aws_security_group.my-new-sg.id]

  subnet_id = aws_subnet.public-subnet.id

  key_name = "my-key-pair"
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install apache2 -y
              sudo systemctl start apache2
              sudo systemctl enable apache2
              sudo bash -c 'echo "<h1>Hello from Terraform</h1>" > /var/www/html/index.html'
              EOF
  tags = {
    "Name" = "ubuntu-server"
  }
}
