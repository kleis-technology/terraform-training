# Introduction to Terraform configurations and language

In this second practical, we will see how to define a Terraform configuration using the Terraform language, the HashiCorp Language (HCL).

### Goal

We will build a Terraform configuration to instantiate a Debian Booster VM in the virtual network.
This instance will be configured to allow SSH connections authenticated with your ssh key.

### Context

A basic AWS infrastructure is provided to you for this practical. It includes
* A virtual network (Amazon Virtual Private Cloud - VPC) 
* A security policy for this network that allows entering ssh connections
* An AWS iam access key and key-pair for you username

## Importing the AWS provider

First, you will indicate to Terraform that you will rely on the AWS provider. 
```HCL
variable "ssh_key_name" {
    type = string
}
```
The list of providers is available [here](https://registry.terraform.io/browse/providers).
The documentation for the AWS can be accessed by selecting AWS and clicking on the `Documentation` tab on the upper right corner (or [here](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)).


## Defining a variable

Then, you will define a `variable` block to identify the SSH public key used that you will use for authentication.

```HCL
variable "ssh_key_name" {
    type = string
}
```
This block informs Terraform that you will provide the `ssh_key_name` as a string to Terraform.

## Declaring a Data Source`

Then, you will define a `data` block that will identify the Amazon Machine Image (AMI) that will run on your AWS Instance.

The `aws_ami` data source allow to identify the Debian buster image that we will use (see [aws_ami](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ami)).
```HCL
data "aws_ami" "debian-buster" {
    owners = [ "136693071363" ]
    most_recent = true
    name_regex = "debian-10-amd64-*"
}
```
This block declares that we want the most recent image from a specific owner (i.e., [debian](https://wiki.debian.org/Cloud/AmazonEC2Image/Buster)) with a given name format.


## Declaring a Resource

Now, we have all the information required to create our first `resource`, that is our Debian buster VM.

An `aws_instance` resource allow us to define our AWS instance on which the Debian buster will run (see [aws_instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance)).
```HCL
resource "aws_instance" "vm" {
    ami = data.aws_ami.debian-buster.id
    instance_type = "t2.nano"
    key_name = var.ssh_key_name
    subnet_id = "subnet-0b0903836b0df7fd5"
    vpc_security_group_ids = [ "sg-0f7591881a7566b35" ]
    associate_public_ip_address = true
    tags = {
      Name = "stage-2-vm"
    }
}
```
* How is the ami image declared in the resource block?
* How is the ssh_key_name is declared ?
* How do we make sure that the instance is reachable from outside?

## Outputs

After the instantiation of the declared resource, we will be interested in recovering the exact AMI ID of the image running on AWS and its associated public IP address.
This can be achieved by declaring an ``output`` objects.

Each output block has a label (e.g., debian_ami_id) and a list of indentifier-value pair that will be returned once the Terraform configuration is applied.
```HCL
output "debian_ami_id" { 
  value = data.aws_ami.debian-buster.id
}
output "vm_ip" {
  value = aws_instance.vm.public_ip
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

ssh -i /PATH/TO/SSH_KEY admin@IP_ADDR
```

4) Destroy your instance when done.
```bash
terraform destroy
```

## Troubleshooting
You can look for the solution of this practical in `tutorials/solutions/stage-2/`.