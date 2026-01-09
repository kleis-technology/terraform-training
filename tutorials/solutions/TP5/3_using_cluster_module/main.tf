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
  backend "s3" {
    acl          = "private"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {}

provider "random" {}

data "aws_ami" "debian_latest" {
  owners      = ["136693071363"]
  most_recent = true
  name_regex  = "debian-13-amd64-*"
}

resource "random_pet" "vm" {
  keepers = {
    # Generate a new pet name each time we switch to a new AMI id
    ami_id = data.aws_ami.debian_buster.id
  }
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

resource "random_pet" "cluster" {}

module "cluster" {
  source = "github.com/kleis-technology/terraform-example-modules.git//modules/cluster?ref=v0.3.0"

  # General arguments
  cluster_name = random_pet.cluster.id

  # Network arguments
  vpc_id                 = data.terraform_remote_state.training.outputs.vpc_id
  subnet_ids             = data.terraform_remote_state.training.outputs.subnet_ids
  vpc_security_group_ids = [data.terraform_remote_state.training.outputs.vm_security_group_id]

  # Instance arguments
  ami_id        = data.aws_ami.debian_latest.id
  instance_type = "t4g.nano"
  ssh_key_name  = var.ssh_key_name
  rendered_user_data = templatefile("user-data.sh", {
    server_name = random_pet.vm.id
  })

  # Autoscaling group arguments
  min_instance = 2
  max_instance = 4
}
