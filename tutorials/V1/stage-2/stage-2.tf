terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
}


data "aws_ami" "debian-buster" {
  owners      = ["136693071363"]
  most_recent = true
  name_regex  = "debian-10-amd64-*"
}

output "debian_ami_id" {
  value = data.aws_ami.debian-buster.id
}


variable "ssh_key_name" {
  type = string
}

resource "aws_instance" "vm" {
  ami                         = "ami-070d3932fe2baaff6" # data.aws_ami.debian-buster.id
  instance_type               = "t4g.micro"             #"t2.nano"
  key_name                    = var.ssh_key_name
  subnet_id                   = "subnet-0b0903836b0df7fd5"
  vpc_security_group_ids      = ["sg-0f7591881a7566b35"]
  associate_public_ip_address = true
  tags = {
    Name = "stage-2-vm"
  }
}

output "vm_ip" {
  value = aws_instance.vm.public_ip
}
