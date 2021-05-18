terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

provider "aws" {
}

provider "random" {
}

data "aws_ami" "debian_buster" {
  owners      = ["136693071363"]
  most_recent = true
  name_regex  = "debian-10-amd64-*"
}

resource "aws_instance" "vm" {
  ami                         = data.aws_ami.debian_buster.id
  instance_type               = "t2.nano"
  key_name                    = var.ssh_key_name
  subnet_id                   = var.subnet
  vpc_security_group_ids      = var.vpc_security_groups
  associate_public_ip_address = true
  tags = {
    Name = "kleis-training-vm"
  }
}
