# Create an AWS Instance running a debian booster

In this second practical, we will see how to define the main objects of the Terraform language.
For that, we will create an AWS Instance running a debian buster image. 

## Context

A basic infrastructure has been set up for you. It includes
* A virtual subnetwork (subnetwork of an Amazon Virtual Private Cloud - VPC)
  * This subnet is identified as ``subnet_id = ID`` (*TODO: provide the ID or point to a config file/variables/set up in stage-2.tf stub?*)
* A security policy for this network that allows entering ssh connections (*and all outgoing?*)
  * This policy is identified as  ``vpc_security_group_ids = ID`` (*TODO: provide the ID or point to a config file/variables/set up in stage-2.tf stub?*)
* AWS iam access key and key-pair allowing you to access to the AWS resources and to user your ssh key as authentication method for ssh
  * Keep track of your AWS username, password and the name of your public key
    
## Aims
1) Manage authentication on the instance (variable)
2) Identify debian-buster image (data source)
3) Define AWS Instance (resource)
4) Recover the instance ID or the public IP of the VM (output)

## Variables

First, you will define a ``variable`` object to identify the SSH public key used to authenticate yourself on the debian buster instance.

This block is defined as follows:
```
variable "ssh_key_name" {
    type = string
}
```

*Other variables or variable file for the subnet_id and vpc_security_group_ids ? *

## Provider?

* [Finding a provider](https://registry.terraform.io/browse/providers)

## Data Sources

Then, you will define a ``data`` object that will identify the Amazon Machine Image (AMI) that will run on your AWS Instance.

The ``aws_ami`` data source allow to identify our ``debian-buster`` image the following block,
```
data "aws_ami" "debian-buster" {
    owners = [ "136693071363" ]
    most_recent = true
    name_regex = "debian-10-amd64-*"
}
```
Here, we declare that we want the *most recent* image from a specific owner (e.g., [debian](https://wiki.debian.org/Cloud/AmazonEC2Image/Buster)) with a given name format.


## Resources

We now have all the information required to create our first ``resource``. This resource will be the AWS Instance running the debian-buster image.

The ``aws_instance`` resource allow ([documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance)) us to define the instance with the following block,
```
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

Now that our instance is defined we are interested in recovering the exact ID of the image instanced on AWS and the associated public IP address.
This is achieved by declaring an ``output`` objects. 

Each output block has a label (e.g., debian_ami_id) and a list of indentifier-value pair that will be returned once the Terraform configuration is applied.
```
output "debian_ami_id" {
  value = data.aws_ami.debian-buster.id
}
output "vm_ip" {
  value = aws_instance.vm.public_ip
}
```

## Building the Terraform configuration

You can now ``plan`` and ``apply`` your Terraform configuration.

Does Terraform has all the information for that (hint: ssh key)?

```bash
terraform init
terraform plan -var "ssh_key_name=YOUR_NAME"
terraform apply -var "ssh_key_name=YOUR_NAME"
terraform output # recover the <IP-address>

ssh -i <private-ssh-key-local-path> admin@<IP-address>
```

*Destroy?*

## Note for self XM:
To get connected: check what is correct?
* Need a ``2048`` or ``4096`` key
* Username for ssh is ``admin``
* The key must not be publicly viewable: ``chmod 400 private-key``
* Command for SSH ``ssh -i ~/.ssh/id_rsa_xme_aws admin@IP``

Should we use "details" blocks for question/answers. E.g., 
<details>
  <summary>Click to expand!</summary>
what?
</details>