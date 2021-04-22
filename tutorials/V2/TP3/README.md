# Using Resources, Data Sources, Variables & outputs

In this practical, we will improve the previous recipe with additional Terraform blocks.

### Goal

We will build a Terraform configuration to instantiate a Debian Booster virtual machine.
The default behavior of this instance will be to allow SSH connections authenticated with your ssh key.
In a second step, we will update this instance to serve a simple web page.


### Context

We restart from the recipe built in the previous practical.

A basic AWS infrastructure is provided to you for this practical. It includes
* A virtual network (Amazon Virtual Private Cloud - VPC)
* A security policy for this network that allows entering ssh connections and tcp connections (on port 8000).
* An AWS iam access key and key-pair associated to your username

#### Setting/resetting recipe
<details>
  <summary>Click here if you need to init/reset your configuration.</summary>

1. Destroy your previous terraform configuration if you had one
```bash
terraform destroy
```
2. Copy the content of `tutorials/V2/solutions/TP2/` in your working directory and apply the configuration.
```bash
# if not done previously
terraform init 
# Use your key name
terraform plan -out terraform.tfplan
# if ok, apply (replace YOUR_KEY_NAME)
terraform apply terraform.tfplan
```
</details>

## Removing the bucket

The bucket used for the previous step won't be required.
Start by removing this resource using the terraform CLI.

#### Solution
<details>
  <summary>Click here to see</summary>

1. Remove the following blocks
```HCL
resource "random_pet" "bucket" {
}
resource "aws_s3_bucket" "bucket" {
   bucket_prefix = "${random_pet.bucket.id}-"
}
```
2. Plan, and apply your configuration (or postpone this step to later).

</details>

## Declaring an AWS Instance

Declaring an AWS instance will require several steps.
1. Finding the ID of the Amazon Machine Image (AMI) that we want to instantiate on our virtual machine.
2. Declaring an AWS instance resource
3. Declaring the `variables`.
4. Declaring the `outputs`

### Finding the AMI ID

We will use a data source to query the AMI from the aws catalog: the [aws_ami](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) data source.

We want to retrieve the latest debian buster (debian 10) image from the official debian aws account.
The debian AWS owner ID can be found on the following [debian webpage](https://wiki.debian.org/Cloud/AmazonEC2Image/Buster),
>  AWS account ID = 136693071363.

We can then use this ID to query the latest debian buster image, using a data block, as follows
```HCL
data "aws_ami" "debian_buster" { 
    owners = [ "136693071363" ]
    most_recent = true
    name_regex = "debian-10-amd64-*"
}
```

This block will provide the `data.aws_ami.debian_buster.id` attribute that returns the AMI id matching our request. 

### Declaring the AWS Instance

Now that we have determined the debian buster AMI id, we will declare our AWS Instance.

For that matter, we will use the [aws_instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) resource.
```HCL
resource "aws_instance" "vm" {
    ami = data.aws_ami.debian_buster.id
    instance_type = "t2.nano"
    tags = { 
       Name = "kleis-training-vm"
    }
}
```
The arguments provided to the `aws_instance` declares that we want to instantiate one `debian_buster` AMI on a Amazon EC2 `t2.nano` instance ([more info](https://aws.amazon.com/ec2/instance-types/t2/)). 
We also associate a AWS tag to this resource.

#### What is missing?

Applying the previous configuration will result in an error (*try it!*).

1. You must define on which Virtual Private Cloud (VPC), that is on which virtual network, your instance will run.
Add the following arguments to your `aws_instance`:
```HCL
    # The subnet in the VPC configured for the kleis-sandbox account
    subnet_id = "subnet-0f496149517fb7839"
    # The security group associated with your account
    vpc_security_group_ids = [ "sg-0a1eb414e2846d207" ]
```

2. More information are missing.
    * Will your virtual machine have a dedicated public IP?
        * *hint*: Look at the [`key_name`  argument](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance#key_name)
    * How will you authenticate yourself on the virtual machine? (*hint* `associate_public_ip_address` argument)
        * *hint*: Look at the [`associate_public_ip_address`  argument](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance#associate_public_ip_address)

3. Update your resource with your `key_name`, and specify whether your want to have an associated public IP.
4. Plan, and apply your configuration when ready.
5. Find the IP address of your virtual machine and establish a ssh connection with it.
   * `ssh -i <PATH/TO/YOUR/KEY> admin@<YOUR_VM_IP>`
   * Provide the path to your private ssh key and your virual machine public IP.

#### Solution
<details>
  <summary>Click here to see</summary>

Expected outcome:
```HCL
resource "aws_instance" "vm" {
    ami = data.aws_ami.debian_buster.id
    instance_type = "t2.nano"
    key_name = ... # YOUR KEY NAME
    subnet_id = "subnet-0f496149517fb7839"
    vpc_security_group_ids = [ "sg-0a1eb414e2846d207" ]
    associate_public_ip_address = true
   tags = {
      Name = "kleis-training-vm"
   }
}
```
2. Plan, and apply your configuration.
3. Is your instance running? Check in the [AWS console](https://eu-west-1.console.aws.amazon.com/ec2/v2/home?region=eu-west-1#Home:)
3. Use `terraform show` to find the public IP of your virtual machine.

</details>

## Using Variables and Outputs to clean-up your configuration

You might want to think about how to simplify the usage of your configuration. 
For instance, consider:
* What if you aren't the only user? (*hint:* inputs +`key_name`)
* How to automatically retrieve your public IP address? (*hint:* outputs + `public_ip`)

### Specifying your variables

Try to decide which variables could be convenient to have as input.

We suggest you to create a `variables.tf` (*good practices!*) and add a variable for the following arguments
* `key_name`
* `subnet_id`
* `vpc_security_group_ids`

You might also want to consider how these variables will be provided to Terraform:
* Environment variables?
* Command line?
* *tfvars* files?

Think about good practices.

#### Solution
<details>
  <summary>Click here to see</summary>

1. `variables.tf` content
```HCL
variable "ssh_key_name" {
  type = string
  description = "Name of the aws key-pair assigned to this user."
}

variable "subnet" {
  type = string
  description = "ID of the AWS subnet declared in the VPC."
}

variable "vpc_security_groups" {
  type = string
  description = "ID(s) of the security groups associated with the VPC."
}


```
2. Update your `aws_instance` resource to use these variables
```HCL
resource "aws_instance" "vm" {
  ami = data.aws_ami.debian_buster.id
  instance_type = "t2.nano"
  key_name = var.ssh_key_name
  subnet_id = var.subnet
  vpc_security_group_ids = var.vpc_security_groups
  associate_public_ip_address = true
  tags = {
    Name = "kleis-training-vm"
  }
}
``` 
3. You could create a `config.auto.tfvars` file. This solution remains unsatisfying though. We will see tomorrow how to solve this issue.

</details>

### Specifying your outputs

Try to decide which outputs could be convenient to have access with `terraform output`.

We suggest you to create a `outputs.tf` (*good practices!*) and add an output for the following attributes
* The ID of the `debian_buster` AMI.
* The public IP of your `vm`.

#### Solution
<details>
  <summary>Click here to see</summary>

1. `outputs.tf` content:
```HCL
output "debian_ami_id" { 
  value = data.aws_ami.debian_buster.id
}

output "vm_ip" {
  value = aws_instance.vm.public_ip
}
```
</details>

### Applying your configuration

Plan, and apply your improved configuration. Use `terraform output` to retrieve your outputs.

*Did that last `apply` resulted in resource deletion and creation, or was it mostly in-place?*


## Serving a webpage from your VM

Why we could be tempted to configure our VM using our working ssh connection... 
It would definitely be against the guiding principles of Infrastructure as Code!

Including the configuration of our VM in our Terraform recipe will solve this issue.
This can be achieved by 
1. Importing a configuration file, or configuration template in the Terraform recipe.
2. Providing the content of said file, or instantiated template, to our VM.

### Importing a configuration file

Locate the `user-data.sh` script available in the `script` folder.
This script simply creates a phony html page and serves it using a `python3` http server (*spoiler: we do not advocate for this approach in practice*).

Note that it contains two *uninitialized variables* (i.e., `${server_name}` and `${server_port}`).

#### Reading a file

Files can be read using the `file` [function](https://www.terraform.io/docs/language/functions/index.html).
The outcome of Terraform functions and expressions can be visualized using the `terraform console` command.

Try typing the following commands in your terminal.
```bash
> terraform console
> file("script/user-data.sh") 
````

#### Instantiating a template file

Declare a [`template_file` data source](https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file) and the `file` function to load and parametrize the `user-data.sh`.
1. Set the `${server_port}` variable to `8000`.
2. Give a name to your server (i.e., `${server_name}`). Use a random pet name to add some flavor!
   * *Hint: Under which occasion will the random pet name change?*
3. Provide the [rendered template](https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file#rendered) to your VM using [the `aws_instance.user_data` argument](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/instance#user_data).
4. Access your `index.html` webpage using the public IP of your VM.


#### Solution

<details>
  <summary>Click here to see</summary>

1. Expected changes in `main.tf`:
```HCL
resource "random_pet" "pet_name" {
   keepers = {
      # Generate a new pet name each time we switch to a new AMI id
      ami_id = data.aws_ami.debian_buster.id
   }
}

data "template_file" "user_data" {
   template = file("user-data.sh")

   vars = {
      server_name = random_pet.pet_name.id
      server_port = var.server_port
   }
}

resource "aws_instance" "vm" {
   ami                         = data.aws_ami.debian_buster.id
   instance_type               = "t2.nano"
   key_name                    = var.ssh_key_name
   subnet_id                   = var.subnet
   vpc_security_group_ids      = var.vpc_security_groups
   associate_public_ip_address = true
   user_data                   = data.template_file.user_data.rendered # Add me!
   tags = {
      Name = "kleis-training-vm"
   }
}
```
2. Expected changes in `variables.tf`:
```HCL
variable "server_port" {
  type = number
  description = "VM port listening for TCP connections."
  default = 8000
}


```
2. Plan, and apply your configuration.
3. Retrieve the `public_ip` of your VM and access the `<public_ip>:8000` address in a navigator.

</details>

## Leads for further exploration

* How would you test if your VM is working properly after provisioning?
* Could that be automated in some way?

## Troubleshooting
You can look for the solution of this practical in `tutorials/solutions/stage-2/`.