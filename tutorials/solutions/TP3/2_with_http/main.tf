terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {}

provider "random" {}

data "aws_ami" "debian_latest" {
  owners      = ["136693071363"]
  most_recent = true
  name_regex  = "debian-13-arm64-*"
}

resource "random_pet" "pet_name" {
  keepers = {
    # Generate a new pet name each time we switch to a new AMI id
    ami_id = data.aws_ami.debian_latest.id
  }
}

resource "aws_instance" "vm" {
  ami                         = data.aws_ami.debian_latest.id
  instance_type               = "t4g.nano"
  key_name                    = var.ssh_key_name
  subnet_id                   = var.subnet
  vpc_security_group_ids      = var.vpc_security_groups
  associate_public_ip_address = true
  user_data = templatefile("user-data.sh", {
    server_name = random_pet.pet_name.id
  })
  tags = {
    Name = "kleis-training-vm"
  }
}
