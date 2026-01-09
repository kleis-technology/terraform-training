# State Storage

In this exercise, we will see how to set up a remote state storage and use external states as data source.

### Goal

- Locate and inspect the state of your Terraform configuration.
- Explore different alternatives for its storage.

### Context

Restart from the code built in the previous exercise.

#### Setting/resetting infrastructure

<details>
  <summary>Click here if you need to init/reset your configuration.</summary>

1. Destroy your previous terraform configuration if you had one

```bash
terraform destroy
```

2. Copy the content of `tutorial/solutions/TP3/2_with_http` in your working directory and apply the configuration.

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

Until now, the state known by terraform of your infrastructure was stored locally.

1. Locate the `terraform.tfstate` file in the current folder.
2. Inspect its content (e.g., using the command `less` or `cat`).
    - Any unexpected additional information?
    - For instance, what about your VM (e.g., number of CPUs, private IP)?

The current state of your configuration can equally be accessed by using the `terraform show` command. For instance, try

```bash
# Terraform formatted
terraform show

# Raw json
terraform show -json

# (optional) Use jq to format or query for values
# jq can be installed with your package manager, e.g.,
# > brew/apt/nix/yum/whatever install jq
terraform show -json | jq .

# Querying the state
terraform state list
terraform state show <RESOURCE_TYPE.RESOURCE_NAME>
```

### Remote state

We are about to migrate the state to a remote storage.

- What are the advantages of doing so?
- What should you be careful of?

### Backend configuration

Configuring Terraform to use a specific state backend is a two steps process.

First, you must provide to Terraform the backend configuration. This configuration can be passed either as arguments, e.g.,

```bash
terraform init --backend-config="key1=value1" --backend-config="key2=value2"
```

or more conveniently (_good practices!_) by providing a file containing these variable definitions, e.g.,

```bash
terraform init --backend-config="backend.tfvars"
```

Then, the backend must be declared in the Terraform code.

```hcl
terraform {
  required_providers {
    ... # Your providers, incl. AWS
  }
  backend "s3" {
    ... # Parameters
  }
```

For this practical, you will use a preconfigured S3 bucket as backend.

Have a quick look at the [S3 backend configuration](https://www.terraform.io/docs/language/settings/backends/s3.html) documentation.

### A minimal backend configuration

First, create the `backend.tfvars` file and add the following information about the S3 bucket

```hcl
region   = "eu-west-1"
profile  = "kleis-sandbox"
role_arn = "arn:aws:iam::717257079239:role/KleisAllowStateBucket-kleis-sandbox"
bucket   = "tfstate-kleis-organization"
key      = "kleis-sandbox/training/remote_state/${YOUR_USERNAME}/terraform.tfstate"
```

These attributes tell Terraform the location of the S3 bucket (_region_ and _bucket_), path to the state file (_key_) and the credentials and
role to assume (_profile_ and _role_arn_).

Make sure to replace `MY_USERNAME` in the `key` attribute with your username.

_Can you figure out what could happen if you don't?_

Then, declare in your code that the state will be stored on an S3 bucket.

```hcl
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

The aforementioned does not:

1. Encrypt the state. Sensitive data would be exposed.
2. Manage concurrent access to the state.
    - That is, protecting the state from concurrent write for instance.

We shall see in the following sections how to setup the remote backend to encrypt and protect the state.

### Adding encryption

To make sure that your state is duly protected, you can use the S3 bucket Server Side Encryption (SSE). This is enabled on the
pre-configured AWS S3 bucket, thus you have to add the key ID in your `backend.tfvars` file.

```hcl
kms_key_id = "4420e6a4-f5a7-4a2d-aa9a-a2b356a82b55"
```

Additionally, you must inform Terraform in your recipe that the backend is encrypted.

```hcl
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

Now, you will make sure that concurrent accesses on the state are made safely.

In order to do so, the `s3` backend provides the `use_lockfile` option, which
you can learn about in the [documentation](https://developer.hashicorp.com/terraform/language/backend/s3#state-locking)

```hcl
# [...]
backend "s3" {
  acl     = "private"
  encrypt = true
  use_lockfile = true
}
```

### Migrating the state

Finally, migrate the local state using the following Terraform command

```
terraform init --backend-config="backend.tfvars"
```

You will be asked if you want to migrate your local state to the remote storage. Answer, `yes`.

The same exact procedure can be used to initialize a Terraform configuration from scratch.

### Solution

<details>
  <summary>Click here to see</summary>

1. `backend.tfvars` content:

```hcl
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

```hcl
terraform {
  required_providers {
    ... # Your providers (incl. AWS)
  }
  backend "s3" {
    acl     = "private"
    encrypt = true
    use_lockfile = true
  }
}
```

</details>

## Referring to Another Remote State

Our current code includes _indirect_ references to an infrastructure provisioned by another Terraform project. Indeed, the network
infrastructure (VPC, subnet, etc.) are declared in a project whose state is stored on the same S3 bucket that we have been using until now.

The state in question is located on the `tfstate-kleis-organization` bucket at the following
location `kleis-sandbox/training/terraform.tfstate`.

Instead of using _indirect_ references, that is using variables for the network configuration, or even worse, a hardcoded string, you will use
explicit references to the other Terraform configuration.

_Can you figure out what are the advantages of doing so ?_

_Can you figure out the risks of doing so ?_

### Importing the Remote State as a Data Source

Importing the remote configuration is achieved by using the `terraform_remote_state` data source (
see [terraform_remote_state](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/data-sources/remote_state)).

```hcl
data "terraform_remote_state" "training" {
  backend = "s3"
  config  = {
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

The remote state is now available as a data source. This remote state declares several `outputs`, including the following:

```hcl
output "subnet_id" {
  value = aws_subnet.training.id
}
output "vm_security_group_id" {
  value = aws_security_group.vm.id
}
```

These `outputs` can now be referenced in the code by prefixing them by: `data.terraform_remote_state.training.outputs`. For instance,
the `subnet_id` can be referred as `data.terraform_remote_state.training.outputs.subnet_id`.

### Updating the recipe

Update your recipe to replace _indirect_ references by references to the other remote state. Then, plan and apply your recipe.

### Solution

<details>
  <summary>Click here so see</summary>

1. Copy the `terraform_remote_state` data block in your configuration.
2. Update your `aws_instance` resource block with references to the imported state outputs.

```hcl
resource "aws_instance" "vm" {
  ami                         = data.aws_ami.debian_latest.id
  instance_type               = "t4g.nano"
  key_name                    = var.ssh_key_name
  subnet_id                   = data.terraform_remote_state.training.outputs.subnet_id # Changed
  vpc_security_group_ids      = [data.terraform_remote_state.training.outputs.vm_security_group_id]  # Changed
  associate_public_ip_address = true
  user_data = templatefile("user-data.sh", {
    server_name = random_pet.pet_name.id
  })
  tags                        = {
    Name = "kleis-training-vm"
  }
}
```

3. Clean-up your `variables.tf` and `config.auto.tfvars` files.
4. Try your new recipe.

</details>

## Bonus: Reformatting your \*.tf Files

By now, you have accumulated numerous changes in your terraform recipe. The indentation in place in your files might no longer
follow [the canonical format and style](https://www.terraform.io/docs/language/syntax/style.html) (_good practices!_).

[The `terraform fmt` command](https://www.terraform.io/docs/cli/commands/fmt.html) is there to help you. From your working directory, call
it as follows

```bash
> terraform fmt -diff .
```

This command will generate a list of changes and reformat your files.

## Bonus: Visualizing the Terraform Dependency Graph

You can export the dependency graph of your current configuration
using [the `terraform graph` command](https://www.terraform.io/docs/cli/commands/graph.html).

For instance, you can directly generate the graph in DOT format corresponding to your configuration by typing

```bash
# Assuming that you are in your working directory
> terraform graph
# Will output the graph in DOT format
```

If you have GraphViz installed on your computer, you can generate a `svg` by typing

```bash
> brew install graphviz # Install dot
> terraform graph | dot -Tsvg > graph.svg
```

Otherwise, just copy the output of the `terraform graph` command and paste in any GraphViz website (
e.g., [this one](https://dreampuf.github.io/GraphvizOnline)). Or alternatively, try installing an external tool (
e.g., [terraform-graph-beautifier](https://github.com/pcasteran/terraform-graph-beautifier)) .

## Troubleshooting

You can look for the solution of this practical in `tutorials/solutions/TP4`.
