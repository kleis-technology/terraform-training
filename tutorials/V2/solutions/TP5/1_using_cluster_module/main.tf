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

resource "random_pet" "vm" {
  keepers = {
    # Generate a new pet name each time we switch to a new AMI id
    ami_id = data.aws_ami.debian_buster.id
  }
}

data "template_file" "user_data" {
  template = file("user-data.sh")

  vars = {
    server_name = random_pet.vm.id
    server_port = var.server_port
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

resource "random_pet" "cluster" {
}

module "cluster" {
  source = "github.com/meyerx/terraform-example-modules.git//modules/cluster?ref=v0.1.0"

  # General arguments
  cluster_name           = random_pet.cluster.id

  # Network arguments
  vpc_id                 = data.terraform_remote_state.training.outputs.vpc_id
  subnet_ids             = data.terraform_remote_state.training.outputs.subnet_ids
  vpc_security_group_ids = [data.terraform_remote_state.training.outputs.vm_security_group_id]

  # Instance arguments
  ssh_key_name           = var.ssh_key_name
  ami_id                 = data.aws_ami.debian_buster.id
  server_port            = var.server_port
  instance_type          = "t2.nano"
  rendered_user_data     = data.template_file.user_data.rendered

  # Autoscaling group arguments
  min_instance           = 2
  max_instance           = 4
}