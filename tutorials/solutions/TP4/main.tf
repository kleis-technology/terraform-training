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
  backend "s3" {
    acl     = "private"
    encrypt = true
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

resource "random_pet" "pet_name" {
  keepers = {
    # Generate a new pet name each time we switch to a new AMI id
    ami_id = data.aws_ami.debian_buster.id
  }
}

data "template_file" "user_data" {
  template = file("user-data.sh")

  vars = {
    server_name = random_pet.pet_name.id
  }
}

data "terraform_remote_state" "training" {
  backend = "s3"
  config = {
    acl            = "private"
    encrypt        = true
    region         = "eu-west-1"
    profile        = "kleis-sandbox"
    role_arn       = "arn:aws:iam::717257079239:role/KleisAllowStateBucket-kleis-sandbox"
    bucket         = "tfstate-kleis-organization"
    key            = "kleis-sandbox/training/terraform.tfstate"
    kms_key_id     = "4420e6a4-f5a7-4a2d-aa9a-a2b356a82b55"
    dynamodb_table = "tfstate-lock"
  }
}

resource "aws_instance" "vm" {
  ami                         = data.aws_ami.debian_buster.id
  instance_type               = "t2.nano"
  key_name                    = var.ssh_key_name
  subnet_id                   = data.terraform_remote_state.training.outputs.subnet_id
  vpc_security_group_ids      = [data.terraform_remote_state.training.outputs.vm_security_group_id]
  associate_public_ip_address = true
  user_data                   = data.template_file.user_data.rendered # Add me!
  tags = {
    Name = "kleis-training-vm"
  }
}
