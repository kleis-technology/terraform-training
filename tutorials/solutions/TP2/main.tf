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

resource "random_pet" "bucket" {}

resource "aws_s3_bucket" "bucket" {
  bucket_prefix = "${random_pet.bucket.id}-"
}
