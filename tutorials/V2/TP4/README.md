# State Storage

In this practical, we will see how to set up a remote state storage and use external states as data source. 

### Goal

* Locate and inspect the State of your Terraform configuration.
* Explore different alternative for its storage.

### Context

We restart from the recipe built in the previous practical.

#### Setting/resetting recipe
<details>
  <summary>Click here if you need to init/reset your configuration.</summary>

1. Destroy your previous terraform configuration if you had one
```bash
terraform destroy
```
2. Copy the content of `tutorials/V2/solutions/TP3/SecondPhase` in your working directory and apply the configuration.
```bash
# if not done previously
terraform init 
# Use your key name
terraform plan -out terraform.tfplan
# if ok, apply (replace YOUR_KEY_NAME)
terraform apply terraform.tfplan
```
</details>



## Local and Remote State

Until now, the state of your terraform configuration was stored locally.
1. Locate the `terraform.tfstate` file in the current folder.
2. Inspect its content  (e.g., using the command `less`). 
   * Any unexpected additional information?
   * For instance, what about your VM (e.g., number of CPUs, private IP)?

The current state of your configuration can equally be accessed by using the `terraform show` command.
For instance, try
```bash
# Terraform formatted
terraform show

# Raw json
terraform show -json

# (optional) Use jq to format or query for values
# jq can be installed with your package manager, e.g., 
# > brew install jq
terraform show -json | jq .

# Querying the state 
terraform state list
terraform state show <RESOURCE_ADDRESS>
```

### Remote state

We are about to migrate the state remotely using the backend of our choice.
* What are the advantages of doing so?
* What should we be careful of?

### Backend configuration

Telling Terraform that we want to use a specific state backend is a two steps process.


First, we must provide to Terraform the backend configuration. 
This configuration can be passed either as arguments, e.g.,
```bash
terraform init
    --backend-config="key1=value1"
    --backend-config="key2=value2"    
```
or more conveniently (*Good Practices!*) by providing a file containing these variable definitions, e.g.,
```bash
terraform init --backend-config="backend.tfvars"
```

Then, the backend must be declared in the Terraform recipe.
```HCL
terraform {
   required_providers {
      ... # Your providers, incl. AWS
   }
   backend "s3" {
      ... # Parameters
   }
```

For this practical, we will use a preconfigured S3 bucket as backend.

Have a quick look at the [S3 backend configuration](https://www.terraform.io/docs/language/settings/backends/s3.html) documentation.

### A minimal backend configuration

First, create the `backend.tfvars` file and add the following information about the S3 bucket
```HCL
region         = "eu-west-1"
profile        = "kleis-sandbox"
role_arn       = "arn:aws:iam::717257079239:role/KleisAllowStateBucket-kleis-sandbox"
bucket         = "tfstate-kleis-organization"
key            = "kleis-sandbox/training/remote_state/YOUR_USERNAME/terraform.tfstate"
```
These attributes inform Terraform on the location of the S3 bucket (*region* and *bucket*), your State path (*key*) and the credientials and role to assume (*profile* and *role_arn*).

Make sure to replace `MY_USERNAME` in the `key` attribute with your username.

*Can you figure out what could happen if you don't?*

Then, declare in your recipe that the state will be stored on an S3 bucket.
```HCL
terraform {
    required_providers {
        ... # Your providers, incl. AWS
    }
    backend "s3" {
        # AWS Access control list
        # Bucket owner has full control
        acl     = "private"
        encrypt = false
    }
}
```

### Is this minimal backend configuration sufficient?

Before migrating the State, you should ask yourself several questions:
1. Do I have sensitive data in my state? Should I encrypt it?
2. Am I the only one working on this configuration?
3. Is the State at risk of being concurrently accessed and written?

Protecting your State from exposure and concurrent access is usually key.

### Adding encryption
To make sure that your state is duly protected, you can use the S3 bucket Server Side Encryption (SSE).
This is enabled on the pre-configured AWS S3 bucket, thus you have to add the key ID in your `backend.tfvars` file.

```HCL
kms_key_id     = "4420e6a4-f5a7-4a2d-aa9a-a2b356a82b55"
```

Additionally, you must inform Terraform in your recipe that the backend is encrypted.
```HCL
terraform {
    required_providers {
        ... # Your providers, incl. AWS
    }
    backend "s3" {
        acl     = "private"
        # Set encrypt to true
        encrypt = true
    }
}
```

### Adding a lock
Now, we must make sure that concurrent accesses on the State are made safely.

At this end, Terraform can use an *AWS Dynamo DB* to lock the access to the remote State file (see [S3 backend configuration](https://www.terraform.io/docs/language/settings/backends/s3.html)).

The pre-configured AWS S3 bucket includes a *AWS Dynamo DB* with a table `tfstate-lock` dedicated to lock Terraform states.
Therefore, adding the name of this table in your `backend.tfvars` file is sufficient to protect your State from concurrent access.
```HCL
dynamodb_table = "tfstate-lock"
```

### Migrating the state

Finally, we can migrate our local state using the following Terraform command
```
terraform init --backend-config="backend.tfvars"
```
You will be asked if you want to copy your local State to the remote storage. Answer, `yes`.

The same exact procedure can be used to initialize a Terraform configuration from scratch.

### Solution

<details>
  <summary>Click here to see</summary>

1. `backend.tfvars` content:
```HCL
region         = "eu-west-1"
profile        = "kleis-sandbox"
role_arn       = "arn:aws:iam::717257079239:role/KleisAllowStateBucket-kleis-sandbox"
bucket         = "tfstate-kleis-organization"
key            = "kleis-sandbox/training/remote_state/YOUR_USERNAME/terraform.tfstate"
kms_key_id     = "4420e6a4-f5a7-4a2d-aa9a-a2b356a82b55"
dynamodb_table = "tfstate-lock"
```
> **Don't forget to update the `key` attribute with your username.**

2. Recipe backend block:
```HCL
terraform {
    required_providers {
      ... # Your providers (incl. AWS)
    }
    backend "s3" {
        acl     = "private"
        encrypt = true
    }
}
```
</details>

## Referring to Another Remote State

Our current recipe includes *indirect* references to an infrastructure provisioned by another Terraform recipe. Indeed, the network infrastructure (VPC, subnet, etc.) are declared in a recipe which state is stored on the same S3 bucket that we have been using until now.

The state in question is therefore located on the `tfstate-kleis-organization` bucket at the following location `kleis-sandbox/training/terraform.tfstate`.

Instead of using *indirect* references, that is using variables for the network configuration, or even worse hardcoded string, we will now use explicit references to the other Terraform configuration.

*Can you figure out what are the advantages of doing so?*

### Importing the Remote State as a Data Source

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
This setting is identical to the one used to store your remote state except for the `key` that points to the other state file.

### Accessing attributes from the remote state

The remote state is now available as a data source.
This remote state declares several `outputs`, including the followings
```HCL
output "subnet_id" {
   value = aws_subnet.training.id
}
output "vm_security_group_id" {
  value = aws_security_group.vm.id
}
```

These `outputs` can now be referenced in our recipe by prefixing them by: `data.terraform_remote_state.training.outputs`.
For instance, the `subnet_id` can be referred as `data.terraform_remote_state.training.outputs.subnet_id`.


### Updating the recipe

Update your recipe to replace *indirect* references by references to the other remote state.
Then, plan and apply your recipe.

### Solution

<details>
  <summary>Click here so see</summary>

1. Copy the `terraform_remote_state` data block in your configuration.
2. Update your `aws_instance` resource block with references to the imported state outputs.
```HCL
resource "aws_instance" "vm" {
   ami                         = data.aws_ami.debian_buster.id
   instance_type               = "t2.nano"
   key_name                    = var.ssh_key_name
   subnet_id                   = data.terraform_remote_state.training.outputs.subnet_id # Changed
   vpc_security_group_ids      = [data.terraform_remote_state.training.outputs.vm_security_group_id]  # Changed
   associate_public_ip_address = true
   user_data                   = data.template_file.user_data.rendered 
   tags = {
      Name = "kleis-training-vm"
   }
}
```
3. Clean-up your `variables.tf` and `config.auto.tfvars` files.
4. Try your new recipe.
</details>

## Bonus: Reformatting your *.tf Files

By now, you have accumulated numerous changes in your terraform recipe. 
The indentation in place in your files might no longer follow [the canonical format and style](https://www.terraform.io/docs/language/syntax/style.html) (*Good Practices!*). 

[The `terraform fmt` command](https://www.terraform.io/docs/cli/commands/fmt.html) is there to help you.
From your working directory, call it as follows
```bash
> terraform fmt -diff .
```
This command will generate a list of changes and reformat your files.

## Leads for further exploration

* Think about which other arguments could benefit from this approach.
* Try to reconnect what we have seen until now with the *Infrastructure as Code guiding principles*.
   * Can you think of any missing *tool* that would help you follow these principles?

## Troubleshooting
You can look for the solution of this practical in `tutorials/V2/solutions/TP4`.



