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

module "webapp" {
  source = "https://gitea.kleis.ch/Public/terraform-training-modules.git//modules/webapp?ref=v0.2.0"

  server_port = var.server_port
}


resource "random_pet" "cluster" {
}

module "cluster" {
  source = "https://gitea.kleis.ch/Public/terraform-training-modules.git//modules/cluster?ref=v0.2.0"

  # General arguments
  cluster_name = random_pet.cluster.id

  # Network arguments
  vpc_id                 = data.terraform_remote_state.training.outputs.vpc_id
  subnet_ids             = data.terraform_remote_state.training.outputs.subnet_ids
  vpc_security_group_ids = [data.terraform_remote_state.training.outputs.vm_security_group_id]

  # Instance arguments
  ssh_key_name       = var.ssh_key_name
  ami_id             = module.webapp.ami_id
  server_port        = var.server_port
  instance_type      = "t2.nano"
  rendered_user_data = module.webapp.rendered_user_data

  # Autoscaling group arguments
  min_instance    = 2
  max_instance    = 4
  instance_warmup = 15 # Making refresh faster
}
