# Using Resources, Data Sources, Variables & outputs

In this exercise, we will improve the previous recipe with additional Terraform blocks.

### Goal

You will build a Terraform configuration to instantiate a Debian virtual machine. The default behavior of this instance will be to
allow SSH connections authenticated with your ssh key. In a second step, you will update this instance to serve a simple web page.

### Context

Restart from the recipe built in the previous exercise.

A basic AWS infrastructure is provided to you for this exercise. It includes :

- A virtual network (Amazon Virtual Private Cloud - VPC)
- A security policy for this network that allows entering ssh connections and tcp connections (on port 8000).
- An AWS iam access key and SSH key-pair associated to your username

#### Setting/resetting recipe

<details>
  <summary>Click here if you need to init/reset your configuration.</summary>

1. Destroy your previous terraform configuration if you had one

```bash
terraform destroy
```

2. Copy the content of `tutorial/solutions/TP2/` in your working directory and apply the configuration.

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

The bucket used for the previous step won't be required. Start by removing this resource using the terraform CLI.

#### Solution

<details>
  <summary>Click here to see</summary>

1. Remove the following blocks

```hcl
resource "random_pet" "bucket" {}

resource "aws_s3_bucket" "bucket" {
  bucket_prefix = "${random_pet.bucket.id}-"
}
```

2. Plan, and apply your configuration (or postpone this step to later).

</details>

## Declaring an AWS Instance

Declaring an AWS instance will require several steps.

1. Finding the ID of the Amazon Machine Image (AMI) that we want to instantiate on the virtual machine.
2. Declaring an AWS instance resource
3. Declaring the `variables`.
4. Declaring the `outputs`

### Finding the AMI ID

You will use a data source to query the AMI from the aws catalog:
the [aws_ami](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) data source.

Retrieve the latest debian (13) image from the official debian aws account. The debian AWS owner ID can be found on the
following [debian webpage](https://wiki.debian.org/Cloud/AmazonEC2Image),

> AWS account ID = 136693071363.

Use this ID to query the latest debian 13 image, using a data block, as follows

```hcl
data "aws_ami" "debian_latest" {
  owners      = ["136693071363"]
  most_recent = true
  name_regex  = "debian-13-arm64-*"
}
```

This block will provide the `data.aws_ami.debian_latest.id` attribute that returns the AMI id matching the request.

### Declaring the AWS Instance

Now that you have determined the latest debian 13 AMI id, you will declare an AWS Instance.

For that, we use the [aws_instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) resource.

```hcl
resource "aws_instance" "vm" {
  ami           = data.aws_ami.debian_latest.id
  instance_type = "t4g.nano"
  tags          = {
    Name = "kleis-training-vm"
  }
}
```

The arguments provided to the `aws_instance` declares that one debian 13 AMI is instantiated on an Amazon EC2 `t4g.nano`
instance ([more info](https://aws.amazon.com/ec2/instance-types/t4/)).

#### What is missing?

Applying the previous configuration will result in an error (_try it!_).

1. You must define on which Virtual Private Cloud (VPC), that is on which virtual network, your instance will run. Add the following
   arguments to your `aws_instance`:

```hcl
# The subnet in the VPC configured for the kleis-sandbox account
subnet_id              = "subnet-05a4e75452749a0ae"
# The security group associated with your account
vpc_security_group_ids = ["sg-0441b1b7eec8de88e"]
```

2. More information is missing to be able to connect to the VM.

    - Will your virtual machine have a dedicated public IP?
        - _hint_: Look at
          the [`associate_public_ip_address` argument](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance#associate_public_ip_address-1)
    - How will you authenticate yourself on the virtual machine?
        - _hint_: Look at
          the [`key_name` argument](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance#key_name-1)

3. Update your resource with your `key_name`, and specify whether you want to have an associated public IP.
4. Plan, and apply your configuration when ready.
5. Find the IP address of your virtual machine and establish a ssh connection with it.
    - `ssh -i <PATH/TO/YOUR/KEY> admin@<YOUR_VM_IP>`

#### Solution

<details>
  <summary>Click here to see</summary>

Expected outcome:

```hcl
resource "aws_instance" "vm" {
  ami                         = data.aws_ami.debian_latest.id
  instance_type               = "t4g.nano"
  key_name                    = ... # YOUR KEY NAME
  subnet_id                   = "subnet-05a4e75452749a0ae"
  vpc_security_group_ids      = ["sg-0441b1b7eec8de88e"]
  associate_public_ip_address = true
  tags                        = {
    Name = "kleis-training-vm"
  }
}
```

2. Plan, and apply your configuration.
3. Is your instance running? Check in the [AWS console](https://eu-west-1.console.aws.amazon.com/ec2/home?region=eu-west-1#Home:)
4. Use `terraform show` to find the public IP of your virtual machine.

</details>

## Using Variables and Outputs to clean-up your configuration

You might want to think about how to simplify your configuration. For instance, consider:

- What if you aren't the only user? (_hint:_ variable inputs +`key_name`)
- How to automatically retrieve your public IP address? (_hint:_ outputs + `public_ip`)

### Specifying your variables

Try to decide which variables could be convenient to have as input.

Create a `variables.tf` (_good practices!_) and add a variable for the following arguments

- `key_name`
- `subnet_id`
- `vpc_security_group_ids`

You might also want to consider how these variables will be provided to Terraform:

- Environment variables?
- Command line?
- _tfvars_ files?

Think about good practices.

#### Solution

<details>
  <summary>Click here to see</summary>

1. `variables.tf` content

```hcl
variable "ssh_key_name" {
  type        = string
  description = "Name of the aws key-pair assigned to this user."
}

variable "subnet" {
  type        = string
  description = "ID of the AWS subnet declared in the VPC."
}

variable "vpc_security_groups" {
  type        = list(string)
  description = "ID(s) of the security groups associated with the VPC."
}
```

2. Update your `aws_instance` resource to use these variables

```hcl
resource "aws_instance" "vm" {
  ami                         = data.aws_ami.debian_latest.id
  instance_type               = "t4g.nano"
  key_name                    = var.ssh_key_name
  subnet_id                   = var.subnet
  vpc_security_group_ids      = var.vpc_security_groups
  associate_public_ip_address = true
  tags                        = {
    Name = "kleis-training-vm"
  }
}
```

3. You could create a `config.auto.tfvars` file. This solution remains unsatisfying though. You will see tomorrow how to solve this issue.

</details>

### Specifying your outputs

Try to decide which outputs could be convenient to have access with `terraform output`.

Create a `outputs.tf` (_good practices!_) and add an output for the following attributes

- The ID of the `debian_latest` AMI.
- The public IP of your `vm`.

#### Solution

<details>
  <summary>Click here to see</summary>

1. `outputs.tf` content:

```hcl
output "debian_ami_id" {
  value = data.aws_ami.debian_latest.id
}

output "vm_ip" {
  value = aws_instance.vm.public_ip
}
```

</details>

### Applying your configuration

Plan, and apply your improved configuration. Use `terraform output` to retrieve your outputs.

_Did that last `apply` result in resource deletion and creation, or was it mostly in-place?_

## Serving a webpage from your VM

While you could be tempted to configure the VM using the working ssh connection... It would definitely be against the guiding principles of
Infrastructure as Code!

Including the configuration of the VM in the Terraform recipe will solve this issue. This can be achieved by

1. Importing a configuration file, or configuration template in the Terraform recipe.
2. Providing the content of said file, or instantiated template, to the VM.

### Importing a configuration file

Locate the `user-data.sh` script available in the `script` folder. This script creates a html page and serves it using
a the nginx server.

Note that it contains an _uninitialized variable_ (i.e. `${server_name}`).

#### Reading a file

Files can be read using the `file` [function](https://www.terraform.io/docs/language/functions/index.html). The outcome of Terraform
functions and expressions can be visualized using the `terraform console` command.

Try typing the following commands in your terminal.

```bash
> terraform console
> file("script/user-data.sh")
```

#### Instantiating a template file

Template files also have their own `templatefile` [function](https://developer.hashicorp.com/terraform/language/functions/templatefile), which you can use to load and fill a template into data, to be then assigned to an attribute. For example, you can provide such data containing a shell script to an aws_instance `user_data` attribute to have that script executed on boot. Use this to load the `user-data.sh` inside an aws_instance, providing it with the required information.

1. Give a name to your server (i.e., `${server_name}`). Use a random pet name to add some flavor!
    - _Hint: Under which occasion will the random pet name change?_
2. Provide the [rendered template](https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file#rendered) to
   your VM
   using [the `aws_instance.user_data` argument](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/instance#user_data)
   .
3. Access your `index.html` webpage using the public IP of your VM.

#### Solution

<details>
  <summary>Click here to see</summary>

1. Expected changes in `main.tf`:

```hcl
# [...]

resource "random_pet" "pet_name" {
  keepers = {
    # Generate a new pet name each time a new AMI id is used
    ami_id = data.aws_ami.debian_latest.id
  }
}

resource "aws_instance" "vm" {
  # ...
  user_data = templatefile("user-data.sh", {
    server_name = random_pet.pet_name.id
  })
}
```

2. Plan, and apply your configuration.
3. Retrieve the `public_ip` of your VM and access the `<public_ip>:8000` address in a navigator.

</details>

## Leads for further exploration

- How would you test if your VM is working properly after provisioning?
- Could that be automated in some way? ([checks](https://developer.hashicorp.com/terraform/language/v1.9.x/checks))

## Troubleshooting

You can look for the solution of this exercise in `tutorials/solutions/TP3/`.
