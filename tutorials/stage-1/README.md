# Introduction to Terraform CLI

In this first practical, we will see how to interact with the Terraform commandline client.

## Credentials
You should have received the following information:
- your username
- your password
- your access key ID
- your secret access key

Your username and password should allow you to log into [AWS web interface](https://console.aws.amazon.com).
You have to use `kleis-sandbox` as account alias.

To be able to use Terraform you need to provide credentials to the AWS provider.
One way to do that is to setup the following environment variables:
- `AWS_REGION="eu-west-1"`
- `AWS_ACCESS_KEY_ID="your_access_key_id"`
- `AWS_SECRET_ACCESS_KEY="your_secret_access_key"`

## Initializing Terraform
To download the needed provider you have to run `terraform init` in the current directory.

If you didn't export the environment variables described above, you can provide them on the fly:
`AWS_REGION="eu-west-1" AWS_ACCESS_KEY_ID="your_access_key_id" AWS_SECRET_ACCESS_KEY="your_secret_access_key" terraform init`

To avoid setting them for each command, you can run:
```bash
export AWS_REGION="eu-west-1"
export AWS_ACCESS_KEY_ID="your_access_key_id"
export AWS_SECRET_ACCESS_KEY="your_secret_access_key"
```

After `terraform init`, a `.terraform` directory should have been created.
It contains a copy of the AWS provider specified in the `stage-1.tf` file.

## Viewing Terraform Plan
Beside provider configuration, the `stage-1.tf` file describes a bucket.

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
