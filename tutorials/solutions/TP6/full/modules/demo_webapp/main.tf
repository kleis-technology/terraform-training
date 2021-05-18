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



module "webapp" {
  source = "https://gitea.kleis.ch/Public/terraform-training-modules.git//modules/webapp?ref=v0.2.0"
}

module "cluster" {
  source = "https://gitea.kleis.ch/Public/terraform-training-modules.git//modules/cluster?ref=v0.2.0"

  # Launching a cluster only if var.max_instance > 1
  count = var.max_instance > 1 ? 1 : 0

  # General arguments
  cluster_name = var.environment_name

  # Network arguments
  vpc_id                 = var.vpc_id
  subnet_ids             = var.subnet_ids
  vpc_security_group_ids = var.vpc_security_group_ids

  # Instance arguments
  ssh_key_name       = var.ssh_key_name
  ami_id             = module.webapp.ami_id
  instance_type      = "t2.nano"
  rendered_user_data = module.webapp.rendered_user_data

  # Autoscaling group arguments
  min_instance = var.min_instance
  max_instance = var.max_instance
  #instance_warmup = 15 # Making refresh faster
}

resource "aws_instance" "webserver" {
  count                       = var.max_instance > 1 ? 0 : 1
  ami                         = module.webapp.ami_id
  instance_type               = "t2.nano"
  key_name                    = var.ssh_key_name
  subnet_id                   = var.subnet_ids[0]
  vpc_security_group_ids      = var.vpc_security_group_ids
  associate_public_ip_address = true
  user_data                   = module.webapp.rendered_user_data
  tags = {
    Name = "kleis-${var.environment_name}-vm"
  }
}
