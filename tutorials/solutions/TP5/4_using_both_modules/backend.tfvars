region   = "eu-west-1"
profile  = "kleis-sandbox"
role_arn = "arn:aws:iam::717257079239:role/KleisAllowStateBucket-kleis-sandbox"
bucket   = "tfstate-kleis-organization"
# TODO
# key            = "kleis-sandbox/training/remote_state/<username>/terraform.tfstate"
kms_key_id     = "4420e6a4-f5a7-4a2d-aa9a-a2b356a82b55"
dynamodb_table = "tfstate-lock"
