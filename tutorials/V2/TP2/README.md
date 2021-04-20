# Introduction to Terraform configurations

In this second practical, we will see how to define a Terraform configuration and explore the Terraform state.

### Goal

We will build a basic Terraform configuration and inspect the terraform state resulting from its deployment.
We will then explore the Terraform state after provisioning.

### Context

You will start this practical from the previous configuration (i.e., `stage-1.tf`).

## Understanding the previous configuration

The starting configuration includes the AWS provider, and an AWS S3 Bucket as resource.

### AWS provider

The AWS provider is declared in two different blocks.

```HCL
# First block
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}
```
1. The first block declare that the AWS provider is required with his source and version.
    * Can you tell who is the maintainer of the AWS provider from the previous declaration?
    * What is the constraint imposed on the version of the provider?
    * Is the provider yet imported?

```HCL
# Second block
provider "aws" {
}
```
2. The second block declare the AWS provider.
    * What happens if we omit this block?

### S3 Bucket

To create an infrastructure, we need at least one resource. 
The following resource block declare an AWS S3 bucket (i.e., a container stored in Amazon S3).

```HCL
resource "aws_s3_bucket" "bucket" {
   bucket_prefix = "stage-1-"
}
```

This code will create a bucket with a unique name prefixed with `stage-1-`.

### Re-apply this configuration

If you have destroyed this configuration in the previous practical, re-apply it.

1) Make sure if the configuration already exists or not.
```bash
# Display the current state of your configuration
terraform show
```
2) If the configuration has been destroyed: initialize Terraform for this configuration
```bash
terraform init
```
3) Then, plan and apply.
```bash
terraform plan -out terraform.tfplan
terraform apply terraform.tfplan
```

### Inspect the state

Inspect the state using
1. The terraform CLI
```bash
terraform show
```
2. By exploring the state file, for instance,
```bash
less terraform.tfstate
```
3. Answer these questions
   * What are the difference between those two representations?
   * Can you find your bucket using the [AWS console](https://s3.console.aws.amazon.com/s3/home?region=us-west-1#)?
    
## Importing and using an additional provider

We will now change this configuration to use a random name in place of the current prefix for the S3 Bucket.
First, we will import the provider Random, and then we will alter our S3 bucket resource.

### Importing a provider

1. Go on the Terraform Registry webpage for the provider random ([direct link](https://registry.terraform.io/providers/hashicorp/random/latest)).
2. Locate the `Use Provider` button, top-right and interact with it.
3. Follow the instruction to install the provider.
   * *Hint: multiple providers constraints can coexist in the `required_providers` block* 
4. (opt) Change the requirements to use the latest 3.1 version of the provider.

Before continuing, answer the following questions:
* Is the provider directly available?
* Does importing a new provider induces changes to my infrastructure?

#### Solution
<details>
  <summary>Click here to see</summary>

1. Declaring the providers:
```HCL
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
    random = {
      source = "hashicorp/random"
      version = "3.1.0"
    }
  }
}

provider "aws" {
}

provider "random" {
}
```

2. Importing them
```bash
> terraform init # download the provider Random
> terraform plan # no effect
````
</details>

### Modifying the S3 Bucket prefix

You can now use the provider `Random` to define a random prefix for you S3 Bucket.

1. Go on the Terraform Registry webpage for the provider random and click on the `Documentation` tab ([direct link](https://registry.terraform.io/providers/hashicorp/random/latest/docs)).
2. Locate the `Resources` panel on the right of the page, and expand the list.
3. Add a `random_pet` resource using the documentation to guide you.
4. Replace the S3 `bucket_prefix` using a reference to the `random_pet` id attribute.
5. Plan, and then apply your configuration.

Before continuing, answer the following questions:
* What happens to the old bucket? Is it updated or recreated from scratch?
* What is the name of your bucket?
* (Opt) Under which condition will this name change?

#### Solution
<details>
  <summary>Click here to see</summary>

1. Add a new `random_pet` resource to your recipe.
```HCL
resource "random_pet" "bucket" {
}
```

2. Update the `aws_s3_bucket` resource to use the `random_pet` attribute.
```HCL
resource "aws_s3_bucket" "bucket" {
   bucket_prefix = "${random_pet.bucket.id}-"
}
```

</details>

### Inspecting the state

As an alternative to opening the state file, or using the `terraform show` command, use the `terrafom state [...]` commands to inspect your state.
1. The `terraform state list` will display all the resources existing in your configuration.
2. The `terraform state show [RESOURCE_ADDRESS]` will display information for the resource in question
   * For instance, try `terraform state show random_pet.bucket`.
   
## Leads for further exploration

* Try to figure out when the random prefix will change.
  * Can you change this behavior?
* Try different random prefix for your bucket.
  * Use more words in the `random_pet` name.
  * Create a random sentence based on `random_pet` names. 
* Try importing another provider of your choice.

## Troubleshooting
You can look for the solution of this practical in `tutorials/solutions/TP2/`.