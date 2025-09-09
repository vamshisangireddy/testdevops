provider "aws" {
  region = var.aws_region
}

# -------------------------------
# VPC
# -------------------------------
resource "aws_vpc" "k8s_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "k8s-vpc"
  }
}

# -------------------------------
# Subnet
# -------------------------------
resource "aws_subnet" "k8s_subnet" {
  vpc_id                  = aws_vpc.k8s_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name = "k8s-subnet"
  }
}

# -------------------------------
# Internet Gateway
# -------------------------------
resource "aws_internet_gateway" "k8s_igw" {
  vpc_id = aws_vpc.k8s_vpc.id
  tags = {
    Name = "k8s-igw"
  }
}

# -------------------------------
# Route Table + Association
# -------------------------------
resource "aws_route_table" "k8s_rt" {
  vpc_id = aws_vpc.k8s_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.k8s_igw.id
  }

  tags = {
    Name = "k8s-rt"
  }
}

resource "aws_route_table_association" "k8s_rta" {
  subnet_id      = aws_subnet.k8s_subnet.id
  route_table_id = aws_route_table.k8s_rt.id
}

# -------------------------------
# Security Group
# -------------------------------
resource "aws_security_group" "k8s_sg" {

  name        = "k8s-sg"
  description = "Allow inbound traffic for K8s + SSH"
  vpc_id      = aws_vpc.k8s_vpc.id
  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "k8s-sg"
  }

  # Allow SSH
  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # change later to Jenkins IP
  }

  # Allow all internal VPC communication
  ingress {
    description = "Internal VPC traffic"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.k8s_vpc.cidr_block]
  }

  # Allow all egress
  egress {
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "-1"
  }
}

# -------------------------------
# Master Node
# -------------------------------
resource "aws_instance" "k8s_master" {

  ami                         = "ami-0945610b37068d87a" # Ubuntu 20.04 LTS in us-west-1
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.k8s_subnet.id
  vpc_security_group_ids      = [aws_security_group.k8s_sg.id]
  key_name                    = var.aws_key_name
  associate_public_ip_address = true

  tags = {
    Name = "k8s-master"
  }
}

# -------------------------------
# Worker Nodes
# -------------------------------
resource "aws_instance" "k8s_workers" {
  count                       = 2
  ami                         = "ami-0945610b37068d87a"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.k8s_subnet.id
  vpc_security_group_ids      = [aws_security_group.k8s_sg.id]
  key_name                    = var.aws_key_name
  associate_public_ip_address = true

  tags = {
    Name = "k8s-worker-${count.index + 1}"
  }
}