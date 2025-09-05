provider "aws" {
  region = "us-east-1" // Change to your preferred region
}

resource "aws_key_pair" "k8s_key" {
  key_name   = "k8s-key"
  public_key = file("~/.ssh/id_rsa_k8s.pub") // Ensure you have this key pair
}

resource "aws_security_group" "k8s_sg" {
  name        = "k8s-sg"
  description = "Allow traffic for K8s cluster"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] // For demo purposes. Restrict to your IP in production.
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "k8s_master" {
  ami           = "ami-0c55b159cbfafe1f0" // Ubuntu 20.04 LTS in us-east-1
  instance_type = "t2.medium"
  key_name      = aws_key_pair.k8s_key.key_name
  security_groups = [aws_security_group.k8s_sg.name]

  tags = {
    Name = "k8s-master"
  }
}

resource "aws_instance" "k8s_worker" {
  count         = 2
  ami           = "ami-0c55b159cbfafe1f0" // Ubuntu 20.04 LTS in us-east-1
  instance_type = "t2.medium"
  key_name      = aws_key_pair.k8s_key.key_name
  security_groups = [aws_security_group.k8s_sg.name]

  tags = {
    Name = "k8s-worker-${count.index + 1}"
  }
}

output "k8s_master_public_ip" {
  value = aws_instance.k8s_master.public_ip
}

output "k8s_worker_ips" {
  value = [for instance in aws_instance.k8s_worker : instance.public_ip]
}