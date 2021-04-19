# Importing a Remote State as Data Source

In this practical, we will see how to use another Terraform remote state as Data Source.

### Goal

Re-use the state of the remote Terraform configuration to configure the network in the current configuration.

### Context

We restart from the recipe built in the previous practical.

Look at the configuration resulting from the previous practical (or from its solution if you did not finish it).
* How was the virtual network declared (i.e., `subnet_id`) ?
* Same for the network security group/policies (i.e., `vpc_security_group_ids`).
* What could be changed ?

#### Setting/resetting the recipe
<details>
  <summary>Click here if you need to init/reset your configuration.</summary>

1. Destroy your previous terraform configuration if you had one
```bash
terraform destroy
```
2. Copy the content of `tutorials/solutions/stage-3/` in your working directory and apply the configuration.
```bash
# if not done previously
terraform init 
# Check the output (replace YOUR_KEY_NAME)
terraform plan -var "ssh_key_name=YOUR_KEY_NAME"
# if ok, apply (replace YOUR_KEY_NAME)
terraform apply -var "ssh_key_name=YOUR_KEY_NAME"
```
</details>

## Configuring the network using the remote state as data source

The remote state of the Terraform configuration used to define the network and its security policy is located on the same AWS S3 bucket you used to store the state of your recipe.

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
This setting is identical to the one used to store your remote state except for the `key` that points to another state file.

### Accessing attributes from the remote state

The remote state is now available as a data source. Let's get the value for `subnet_id` and `vpc_security_group_ids`.
These values can be found in the output of the remote state and are prefixed by: `data.terraform_remote_state.training.outputs`.
You can access the remote stats using the following [URL](https://tfstate-kleis-organization.s3.eu-west-1.amazonaws.com/kleis-organization/terraform.tfstate?response-content-disposition=inline&X-Amz-Security-Token=IQoJb3JpZ2luX2VjEOH%2F%2F%2F%2F%2F%2F%2F%2F%2F%2FwEaDGV1LWNlbnRyYWwtMSJGMEQCIDgKauwJJhwY9BtpJ23xWPR6EV6F40BFS23NVIgJvaRkAiBJhnvVXgbTtjz0dwXgrgf8PCFfBJKtwyJB9acMYkwgXSryAwgaEAAaDDcxNzI1NzA3OTIzOSIMK6ZJCbYkJJJYN1nvKs8Dm8KwwPvgA3Zzr5y8KK5lt55NBWWs52CjBOABRJwoWFX5L%2FsCEB2b4%2BdEGysOtVrgldKi%2FHHiAP1ULfCC906DBn2S0l6b1%2B%2FVz1kwN%2BxdJ%2FITBquCHDxq6iZa5M7Ibgjk9MwmCQqXinc6eVDD93tz8lFptQVJ%2BVoz5nPDNNg4fU5tB%2F%2BW63sSR8iJY1hR9D2nEndaEy8iqYIrgw%2FPnfYy%2B5GFLGf%2F1QluUHiIfA1OwwAH7GzN7QEjiZZc%2BV0hkIvtFFNIJlNdOX79UsVbtVU4Rz4TymeoqY1JIo2SevsPazitaMmu8jRgzlYRhgw9%2FtkZ6gpP7I4iIcBJudzeooLLXhHjOiffGkqlopme0KG7SJMLYQnRqRRU6X%2B%2B5RIt6maPONqrRzpAafEoNhAm7zKBp8mxAIXSPefSj%2BD6Pad0XEgUjJQmmfPCIZRjKafNdu5G8vhf8mYsL4G4DlSy2JkUauWAN3qGiZ68LXdO7JCY0ounhPBFpDQTEZ4KZdWXqLxbUhotuRWwx73CoLgOArhs8KSR%2FWnKsedTbzWy6jLMJDrkNvmE0QMH%2F87CcBnrZNhTvfon3P6xqL9hEIWbgZLIMU1FS3rW5gJPk4ZiDTAC1zCLvMOCBjqVAt%2FMjgfLuiVrXhzzpk8EBxmVVPIbXWut6ulKIDajVKpsdVx%2F3xhH6bWKCVRfCV1QJP7sRl0SsV20W%2FGSvsYl2EfmUNwYG9qMy%2BCv2U2x5bZBb4bIyHasGEYSo%2FlF8scWq1n467e6Y7eiJtk8vUzDDctia3xEEFeNFSxwe%2ByDW221jQX1bmqJELgltKGt%2Fn%2FMsgq0zq5VEb6ODNSk3AC%2BDBXYhE%2FBHkOmxVadDevT46trgoy2f4BkKvAZ0d9Zo0%2F1SKpEFgeK5KCGQiiAy6t3y80w0oQ42sWg%2FINXHBU9dI1YbjV%2FsJ73qh7czR5YQlT8Ybn5Nr16gWG2r6MAf2os8UanrJkXoIZPCpSVeuQb55Yl8C8OMFk%3D&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Date=20210316T163510Z&X-Amz-SignedHeaders=host&X-Amz-Expires=300&X-Amz-Credential=ASIA2N762PHDZ35RYBLG%2F20210316%2Feu-west-1%2Fs3%2Faws4_request&X-Amz-Signature=d971416f4ffbbb72ee9d056299b986d6903e240a2e0013e24d0cb2f40132cda0).

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

## Troubleshooting
You can look for the solution of this practical in `tutorials/solutions/stage-4/`.