# Importing a Remote State as Data Source

In this third practical, we will see how to use another Terraform remote state as Data Source.

### Goal

Re-use the state of the remote Terraform configuration to configure the network in the current configuration.

### Context

Look at the configuration of the previous practical: `stage-2.tf`.
* How was the virtual network declared (i.e., `subnet_id`) ?
* Same for the network security group/policies (i.e., `vpc_security_group_ids`).
* What could be changed ?

## Configuring the network using the remote state

The remote Terraform configuration is located on an encrypted AWS S3 bucket owned by the `kleis-organization` AWS organization.

### Importing the remote state as data source

Importing the remote configuration is achieved by using the `terraform_remote_state` data source (see [terraform_remote_state](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/data-sources/remote_state)).
```HCL
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
```

### Accessing attributes from the remote state

The remote state is now available as a data source. Let's get the value for `subnet_id` and `vpc_security_group_ids`.
These values can be found in the output of the remote state and are prefixed by: `data.terraform_remote_state.training.outputs`.

We therefore update our previous declaration `aws_instance` to import the `subnet_id` and `vpc_security_group_ids`.
```HCL
resource "aws_instance" "vm" {
    ami = data.aws_ami.debian-buster.id
    instance_type = "t2.nano"
    key_name = var.ssh_key_name
    subnet_id = data.terraform_remote_state.training.outputs.subnet_id
    vpc_security_group_ids = [data.terraform_remote_state.training.outputs.vm_security_group_id]
    associate_public_ip_address = true
    tags = {
        Name = "stage-2-vm"
    }
}
```

## Using the Terraform configuration

1) Initialize Terraform for this configuration
```bash
terraform init
```

2) Plan and when satisfied apply the configuration (replace `YOUR_KEY_NAME` with your username/key name).
```bash
terraform plan -var "ssh_key_name=YOUR_KEY_NAME"
terraform apply -var "ssh_key_name=YOUR_KEY_NAME"
```

3) Recover the outputs and log onto the Debian instance using your SSH key
```bash
terraform output # recover your IP_ADDR

ssh -i PATH_TO_KEY admin@IP_ADDR
```

4) Destroy your instance when done.
```bash
terraform destroy
```