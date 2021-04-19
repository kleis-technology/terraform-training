# State storage

In this practical, we will interact with the State of your Terraform configuration.

### Context

We restart from the recipe built in the previous practical.

#### Setting/resetting recipe
<details>
  <summary>Click here if you need to init/reset your configuration.</summary>

1. Destroy your previous terraform configuration if you had one
```bash
terraform destroy
```
2. Copy the content of `tutorials/solutions/stage-2/` in your working directory and apply the configuration.
```bash
# if not done previously
terraform init 
# Check the output (replace YOUR_KEY_NAME)
terraform plan -var "ssh_key_name=YOUR_KEY_NAME"
# if ok, apply (replace YOUR_KEY_NAME)
terraform apply -var "ssh_key_name=YOUR_KEY_NAME"
```
</details>

### Goal

* Locate and inspect the State of your Terraform configuration.
* Explore different alternative fo its storage.

## Local state

By default, the state of your Terraform configuration is stored locally. 

1. Locate the `terraform.tfstate` file in the current folder.
2. Inspect its content  (e.g., using the command `cat`).

*What kind of information can you find in the state?*
* The outputs?
* Any additional information about your VM (e.g., number of CPUs, private IP)?

The current state of your configuration can equally be accessed by using the `terraform show` command.
For instance, try
```bash
# Terraform formated
terraform show

# Raw json
terraform show -json

# (optional) Use jq to format or query for values
terraform show -json | jq .
```

*What are the limitation of using a local state?*

## Remote state

We will now migrate the configuration State to a remote storage.

### A minimal backend configuration

The configuration of the backend that will store the remote State can be passed either as arguments, e.g.,
```bash
terraform init
    --backend-config="key1=value1"
    --backend-config="key2=value2"    
```
or more conveniently by providing a file containing these variable definitions, e.g.,
```bash
terraform init --backend-config="backend.tfvars"
```

For this practical, the State will be stored on a pre-configured AWS S3 bucket (see [S3 bakend configuration](https://www.terraform.io/docs/language/settings/backends/s3.html)).

First, create the `backend.tfvars` file and add the following information about the S3 bucket
```HCL
region         = "eu-west-1"
profile        = "kleis-sandbox"
role_arn       = "arn:aws:iam::717257079239:role/KleisAllowStateBucket-kleis-sandbox"
bucket         = "tfstate-kleis-organization"
key            = "kleis-sandbox/training/stage-4/YOUR_USERNAME/terraform.tfstate"
```
These attributes inform Terraform on the location of the S3 bucket (*region* and *bucket*), your State path (*key*) and the credientials and role to assume (*profile* and *role_arn*).

Make sure to replace `MY_USERNAME` in the `key` attribute with your username. 

*Can you figure out what might happen if you don't?*

Finally, you must declare in your recipe that the state will be stored on an S3 bucket.
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
1. Do I have sensitive data in my State? Should I encrypt it?
2. Am I the only one working on this configuration?
3. Is the State at risk of being concurrently accessed and written?

Protecting your State from exposure and concurrent access is usually key.

### Adding encryption
To make sure that your State is duly protected, you can use the S3 bucket Server Side Encryption (SSE).
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
Now, we must make sure that concurrent accesses on the State are made safe.
Terraform can use an *AWS Dynamo DB* to lock access to the remote State file (see [S3 bakend configuration](https://www.terraform.io/docs/language/settings/backends/s3.html)).

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

The same exact procedure can be used to initialize a Terraform configuration for the first time.

## Troubleshooting
You can look for the solution of this practical in `tutorials/solutions/stage-3/`.

<details>
  <summary>Or click here to see the changes you should have made.</summary>

Recipe backend block:
```HCL
terraform {
    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "~> 3.0"
        }
    }
    backend "s3" {
        acl     = "private"
        encrypt = true
    }
}
```

`backend.tfvars` content:
```HCL
region         = "eu-west-1"
profile        = "kleis-sandbox"
role_arn       = "arn:aws:iam::717257079239:role/KleisAllowStateBucket-kleis-sandbox"
bucket         = "tfstate-kleis-organization"
key            = "kleis-sandbox/training/stage-4/YOUR_USERNAME/terraform.tfstate"
kms_key_id     = "4420e6a4-f5a7-4a2d-aa9a-a2b356a82b55"
dynamodb_table = "tfstate-lock"
```
Don't forget to update the `key` attribute with your username.

</details>


