terraform {
  required_version = ">= 1.10"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    use_lockfile = true
    # bucket, key, region passed via -backend-config at init time
  }
}

provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  default = "us-east-1"
}

variable "service_name" {
  default = "memory-match"
}

# ---------- data: latest Amazon Linux 2023 AMI ----------
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ---------- security group (default VPC) ----------
data "aws_vpc" "default" {
  default = true
}

resource "aws_security_group" "memory_match" {
  name        = "${var.service_name}-sg"
  description = "HTTP and SSH for memory-match"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.service_name}-sg" }
}

# ---------- EC2 instance ----------
resource "aws_instance" "memory_match" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = "t3.micro"
  vpc_security_group_ids      = [aws_security_group.memory_match.id]
  associate_public_ip_address = true

  user_data_replace_on_change = true

  user_data = <<-EOF
    #!/bin/bash
    set -e
    dnf update -y
    dnf install -y nginx git
    # copy game files
    REPO_DIR=/tmp/memory-match
    git clone https://github.com/${var.github_owner}/memory-match.git $REPO_DIR
    cd $REPO_DIR && git checkout ${var.git_revision}
    cp $REPO_DIR/index.html /usr/share/nginx/html/
    cp $REPO_DIR/style.css  /usr/share/nginx/html/
    cp $REPO_DIR/game.js    /usr/share/nginx/html/
    # start nginx
    systemctl enable nginx
    systemctl start nginx
  EOF

  tags = { Name = var.service_name }
}

variable "github_owner" {
  description = "GitHub owner/org that hosts the memory-match repo"
  default     = "talhajubayerrbai"
}

variable "git_revision" {
  description = "Git commit SHA to deploy — changing this forces instance replacement"
  default     = "main"
}

# ---------- outputs ----------
output "public_ip" {
  value = aws_instance.memory_match.public_ip
}

output "public_dns" {
  value = aws_instance.memory_match.public_dns
}

output "url" {
  value = "http://${aws_instance.memory_match.public_ip}"
}
