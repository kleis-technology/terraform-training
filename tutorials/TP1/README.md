# Introduction to Terraform CLI

In this practical, we will set up your environment and see how to interact with the Terraform commandline client.

## Setting up your environment

You have to install a few packages, including terraform.
Open a terminal, and install the following packages using your favorite package management system (e.g., homebrew/aptitude/yay).

1. Git
   - macOS: `brew install git`
   - debian: `sudo apt-get install git`
1. The AWS Command Line Interface
   - macOS: `brew install awscli`
   - debian: `sudo apt-get install awscli`
1. The Terraform Command Line Interface
   - Follow the [guide on Terraform website](https://learn.hashicorp.com/tutorials/terraform/install-cli#install-terraform)
1. Optional
   - If you are using `antigen` to customize your shell, you may want to update your shell configuration with
     - `antigen bundle aws`
     - `antigen bundle terraform`,
1. Check your installation with
   - `git --version`
   - `aws --version`
   - `terraform --version` _(v0.14+ required)_

You are now ready to start the first TP.

## Credentials

You should have received the following information:

- your username
- your password
- your access key ID
- your secret access key

### Accessing the AWS console

Your username and password should allow you to log into [AWS web interface](https://console.aws.amazon.com).

1. Chose `IAM user`
2. Account ID: `kleis-sandbox`
3. Enter your username and password

### Preparing your shell environment

To be able to use Terraform you need to provide credentials to the AWS provider.
One way to do that is to setup the following environment variables:

```bash
export AWS_REGION="eu-west-1"
export AWS_ACCESS_KEY_ID="your_access_key_id"
export AWS_SECRET_ACCESS_KEY="your_secret_access_key"
```

## Initializing Terraform

To initialize your Terraform configuration, you have to run `terraform init` in the current directory.

After `terraform init`, a `.terraform` directory should have been created.
It contains a copy of the AWS provider specified in the `main.tf` file.

## Viewing Terraform Plan

Beside provider configuration, the `main.tf` contains an aws resource (i.e., a bucket).

If you run `terraform plan`, you should see that Terraform wants to create this bucket.

To store this plan, run `terraform plan -out terraform.tfplan`.

This is the way to ensure that what you'll execute later matches the plan that you just checked.

## Applying Planned Modifications

You can now run `terraform apply terraform.tfplan` to execute the planned actions that were stored in the plan file.

A new file should have appeared: `terraform.tfstate`.
If you open it you should see a description of the resources that have been created.

## Making Sure Everything is in Order

Since nothing changed in the code describing the wanted resources, if you run `terraform plan` again, you should see `No changes. Infrastructure is up-to-date.`.

## Cleaning Up

To destroy the resources that we created, we can run: `terraform destroy`.
After confirmation, it will destroy all the resources that have been created (according to the `terraform.tfstate` file).

Once you ran that, you can check the `terraform.tfstate` file, it should now be almost empty, since the resources that were created and tracked have now been destroyed.
