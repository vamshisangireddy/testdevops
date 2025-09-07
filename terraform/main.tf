provider "aws" {
  region = var.aws_region
}

resource "aws_vpc" "k8s_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "k8s-vpc"
  }
}

resource "aws_subnet" "k8s_subnet" {
  vpc_id     = aws_vpc.k8s_vpc.id
  cidr_block = "10.0.1.0/24"
  tags = {
    Name = "k8s-subnet"
  }
}

resource "aws_security_group" "k8s_sg" {
  name        = "k8s-sg"
  description = "Allow all inbound traffic for K8s"
  vpc_id      = aws_vpc.k8s_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "k8s_master" {
  ami           = "ami-0945610b37068d87a" # Ubuntu 20.04 LTS in us-east-1, change if needed
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.k8s_subnet.id
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]
  key_name      = var.aws_key_name
  associate_public_ip_address = true

  tags = {
    Name = "k8s-master"
  }
}

resource "aws_instance" "k8s_workers" {
  count         = 2
  ami           = "ami-0945610b37068d87a" # Ubuntu 20.04 LTS in us-east-1, change if needed
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.k8s_subnet.id
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]
  key_name      = var.aws_key_name
  associate_public_ip_address = true

  tags = {
    Name = "k8s-worker-${count.index + 1}"
  }
}