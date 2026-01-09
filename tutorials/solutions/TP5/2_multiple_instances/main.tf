terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
  backend "s3" {
    acl          = "private"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {}

data "aws_ami" "debian_latest" {
  owners      = ["136693071363"]
  most_recent = true
  name_regex  = "debian-13-amd64-*"
}

data "terraform_remote_state" "training" {
  backend = "s3"
  config = {
    acl          = "private"
    encrypt      = true
    region       = "eu-west-1"
    profile      = "kleis-sandbox"
    role_arn     = "arn:aws:iam::717257079239:role/KleisAllowStateBucket-kleis-sandbox"
    bucket       = "tfstate-kleis-organization"
    key          = "kleis-sandbox/training/terraform.tfstate"
    kms_key_id   = "4420e6a4-f5a7-4a2d-aa9a-a2b356a82b55"
    use_lockfile = true
  }
}

resource "aws_instance" "webservers" {
  for_each = toset(var.cattle_names)

  ami                         = data.aws_ami.debian_latest.id
  instance_type               = "t4g.nano"
  key_name                    = var.ssh_key_name
  subnet_id                   = data.terraform_remote_state.training.outputs.subnet_id
  vpc_security_group_ids      = [data.terraform_remote_state.training.outputs.vm_security_group_id]
  associate_public_ip_address = true
  user_data = templatefile("user-data.sh", {
    server_name = each.key
  })
  tags = {
    Name = "kleis-training-webserver-${each.key}"
  }
}
