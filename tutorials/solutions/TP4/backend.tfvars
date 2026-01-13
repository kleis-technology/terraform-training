region = "eu-west-1"
assume_role = {
  role_arn = "arn:aws:iam::717257079239:role/KleisAllowStateBucket-kleis-sandbox"
}
bucket     = "tfstate-kleis-organization"
key        = "kleis-sandbox/training/remote_state/jde/terraform.tfstate"
kms_key_id = "4420e6a4-f5a7-4a2d-aa9a-a2b356a82b55"
