# Using Meta-Arguments and External Modules

In this practical, we will see how to use meta-arguments to create multiple resources and how to call modules from our recipe.

### Goal

* Interact with meta-arguments
* Import external modules stored on a Git repository

### Context

Restart from the recipe built in the previous practical.

#### Setting/resetting recipe
<details>
  <summary>Click here if you need to init/reset your configuration.</summary>

1. Destroy your previous terraform configuration if you had one
```bash
terraform destroy
```
2. Copy the content of `tutorial/solutions/TP4` in your working directory and apply the configuration.
```bash
# if not done previously
terraform init 
# Use your key name
terraform plan -out terraform.tfplan
# if ok, apply (replace YOUR_KEY_NAME)
terraform apply terraform.tfplan
```
</details>

## Using Meta-Arguments

We will consider different scenarios in which using meta-arguments could prove useful.

### Conditional instance configuration

In the first scenario, you will create an *if-else* condition defining the configuration of your virtual machine.

The *HashiCorp Language* (HCL) doesn't support *if-else* statements.
You will have to use an alternative approach create such statement.

* Add a new boolean variable named `with_webpage`.
  * If `with_webpage` then your instance will only accept ssh connections.
  * Else the instance will accept ssh connections and serve a webpage.
* *Hint: think about [the meta-argument `count`](https://www.terraform.io/docs/language/meta-arguments/count.html) and [the ternary operator](https://www.terraform.io/docs/language/expressions/conditionals.html)*.

#### Solution
<details>
  <summary>Click here to see.</summary>
1. Add an the input variable.

```hcl
variable "with_webpage" {
  description = "Boolean defining if the a webpage is served."
  type = bool
}
```

2. Duplicate and modify your `aws_instance`(s).

```hcl
resource "aws_instance" "only_ssh_vm" {
  # Create one instance if var.withHTTP is set to false
  count                       = var.with_webpage ? 0 : 1
  ami                         = data.aws_ami.debian_buster.id
  instance_type               = "t2.nano"
  key_name                    = var.ssh_key_name
  subnet_id                   = data.terraform_remote_state.training.outputs.subnet_id
  vpc_security_group_ids      = [data.terraform_remote_state.training.outputs.vm_security_group_id]
  #user_data                   = data.template_file.user_data.rendered
  associate_public_ip_address = true
  tags = {
    Name = "kleis-training-ssh-vm"
  }
}

resource "aws_instance" "webserver_vm" {
  # Create one instance if var.withHTTP is set to true
  count                       = var.with_webpage ? 1 : 0
  ami                         = data.aws_ami.debian_buster.id
  instance_type               = "t2.nano"
  key_name                    = var.ssh_key_name
  subnet_id                   = data.terraform_remote_state.training.outputs.subnet_id
  vpc_security_group_ids      = [data.terraform_remote_state.training.outputs.vm_security_group_id]
  associate_public_ip_address = true
  user_data                   = data.template_file.user_data.rendered
  tags = {
    Name = "kleis-training-webserver-vm"
  }
}
```

3. Adapt your output. This solution shows how to use [string directives](https://www.terraform.io/docs/language/expressions/strings.html#directives).

```hcl
output "vm_ip" {
  # We use a 'if string directive' to select the proper aws_instance.
  # The index of the instance must be specified given the use of 'count'.
  value = "%{ if var.with_webpage }${aws_instance.webserver_vm[0].public_ip}%{ else }${aws_instance.only_ssh_vm[0].public_ip}%{ endif }"
}
```

</details>

### Multiple instances with different configurations

In this scenario, you will create multiple virtual machines with different configurations.

Let's assume that the configuration script has different behaviors in function of its assigned virtual machine name.
The machine names would be provided as input variables, e.g.,
```hcl
variable "cattle_names" {
  description = "Cattle names."
  type        = list(string)
  default = [
    "mighty_panda",
    "giant_owl",
    "cute_beaver"
  ]
}
```
For each name in the list, a virtual machine will be instantiated.
Have a look at the `user-data.sh`script provided with this TP to understand how different behavior are enforced.

* Re-use the `template_file` and `aws_instance` resources.
  * Don't duplicate them.
  * *Hint: Think about *for-like* statements supported by HCL.*

#### Solution

<details>

  <summary>Click here to see.</summary>

1. Use [a `for_each` meta-argument](https://www.terraform.io/docs/language/meta-arguments/for_each.html), for instance.
2. Modify your  `template_file` and `aws_instance` resources.
```hcl
data "template_file" "webservers" {
  for_each = toset(var.cattle_names)

  template = file("user-data.sh")

  vars = {
    server_name = each.key
    server_port = var.server_port
  }
}

resource "aws_instance" "webservers" {
  for_each = toset(var.cattle_names)

  ami                         = data.aws_ami.debian_buster.id
  instance_type               = "t2.nano"
  key_name                    = var.ssh_key_name
  subnet_id                   = data.terraform_remote_state.training.outputs.subnet_id
  vpc_security_group_ids      = [data.terraform_remote_state.training.outputs.vm_security_group_id]
  associate_public_ip_address = true
  user_data                   = data.template_file.webservers[each.key].rendered
  tags = {
    Name = "kleis-training-webserver-${each.key}"
  }
}
```
3. Don't forget to adapt your `vm_ips` outputs.
```hcl
output "vm_ips" {
  value = tomap({
    for name, webserver in aws_instance.webservers : name => webserver.public_ip
  })
}
```
</details>

## Using modules

Terraform modules make it easier to organize, reuse, share and import Infrastructure as Code.

In this exercise, you will use two example modules.
These modules are put at your disposal [on a Git repository](https://github.com/meyerx/terraform-example-modules).

This Git repository contains the modules
* `webapp` in folder `modules/webapp`
* `cluster` in folder `modules/cluster`

Start by using the `v0.1.0` version of these modules that provides
* A simple `webapp` *configuration*: that is, an AMI and a rendered configuration script.
* A simple functional `cluster`.

### Using a module to replace a single AWS Instance by a cluster
 
In this scenario, you will put the "web application" in production. 
Here, the load is expected to vary across time. The webapp is therefore migrated on an autoscaling cluster with a load balancer.
Provisioning an [AWS autoscaling group](https://docs.aws.amazon.com/autoscaling/ec2/userguide/AutoScalingGroup.html) with an [application load balancer](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/introduction.html) requires a considerable effort.

The `cluster` module will allow doing that without the hassle of setting up everything ourselves.

#### 1. Importing the module

First, add the module into your recipe as follows
```hcl
module "cluster" {
  source = "github.com/meyerx/terraform-example-modules.git//modules/cluster?ref=v0.1.0"
  # No arguments for now
}
```
This simply declares to use the module `cluster`.
* From the github repository `meyerx/terraform-example-modules.git`
* Located in the `//modules/cluster`
* With version `?ref=v0.1.0` (i.e., Git tag in this case) 

Then, run `terraform init -backend-config="backend.tfvars"`
  * The module is now downloaded in your `.terraform/` folder.
  * Locate it and have a look at the `inputs.tf` file.

Finally, run `terraform plan`. *What happens?*
#### 2. Configuring the module

Try configuring the module on your own by reusing values already defined in your recipe.

<details>
 <summary>Click here for a solution.</summary>

This configuration re-use
* The `terraform_remote_state`
* The parameters originally given the `aws_instance`

and defines that

* the autoscaling group will vary between `2` and `4` instances

```hcl
module "cluster" {
  source = "github.com/meyerx/terraform-example-modules.git//modules/cluster?ref=v0.1.0"

  ## General arguments
  cluster_name = random_pet.cluster.id

  ## Network arguments
  vpc_id                 = data.terraform_remote_state.training.outputs.vpc_id
  subnet_ids             = data.terraform_remote_state.training.outputs.subnet_ids
  vpc_security_group_ids = [data.terraform_remote_state.training.outputs.vm_security_group_id]

  ## Instance arguments
  ssh_key_name       = var.ssh_key_name
  ami_id             = data.aws_ami.debian_buster.id
  server_port        = var.server_port
  instance_type      = "t2.nano"
  rendered_user_data = data.template_file.user_data.rendered

  ## Autoscaling group arguments
  min_instance = 2
  max_instance = 4
}
```

</details>


#### 3. Replacing your aws instance

Now that your module is configured, remove your `aws_instance` declaration(s) and adapt your outputs.
```hcl
# Content of your outputs.tf
output "debian_ami_id" {
  value = data.aws_ami.debian_buster.id
}

output "alb_dns_name" {
  value       = module.cluster.alb_dns_name
  description = "The domain name of the load balancer"
  # You can use it to reach the webserver.
}

output "asg_name" {
  value       = module.cluster.asg_name
  description = "The name of the Auto Scaling Group"
}
```

#### 4. Outcome

Plan and apply your recipe.
* You should now see numerous new resources created on your [AWS console](https://eu-west-1.console.aws.amazon.com/ec2/v2/home?region=eu-west-1#Home:). 
   * Locate the `autoscaling group`, and the `load balancer` on the left-hand menu.
   * Inspect them.
* Access your webpage using
  * The load balancer address (*don't forget the port*).
  * Each virtual machine IP.
  * *What do you observe?*
  
### Replacing the image configuration by an external module

You will now replace the configuration of the instances using the `webapp` module.

Follow the same procedure used for the `cluster` module.
1. Import the module `webapp` v0.1.0 that can be retrieved using the following address
      > github.com/meyerx/terraform-example-modules.git//modules/webapp?ref=v0.1.0"
2. Configure the module `webapp`.
3. Remove the `random_pet`, `aws_ami` and `template_file` resources.
4. Plan, and when ready, apply.
5. Access your webservers using the load balancer url.
   * Try refreshing the webpage several times. Does the name changes?
   * Validate this observation using the following shell commands
      ```bash
      > LB_URL="..." # Plug your load balancer URL
      > WEBSERVER_PORT="..." # Plug the port you used for your webserver
      > clear; for i in $(seq 1 10000); do tput cup 0 0; curl "${LB_URL}:${WEBSERVER_PORT}"; sleep 0.1; done;
      ```
   * Again, does the name change? Why?

#### Solution
<details>
  <summary>Click here to see.</summary>

1. Module `webapp` and `module` setting
```HCL

module "webapp" {
  source = "github.com/meyerx/terraform-example-modules.git//modules/webapp?ref=v0.1.0"

  server_port = var.server_port
}

module "cluster" {
  source = "github.com/meyerx/terraform-example-modules.git//modules/cluster?ref=v0.1.0"

  # General arguments
  cluster_name = random_pet.cluster.id

  # Network arguments
  vpc_id                 = data.terraform_remote_state.training.outputs.vpc_id
  subnet_ids             = data.terraform_remote_state.training.outputs.subnet_ids
  vpc_security_group_ids = [data.terraform_remote_state.training.outputs.vm_security_group_id]

  # Instance arguments
  ssh_key_name       = var.ssh_key_name
  ami_id             = module.webapp.ami_id # Change me
  server_port        = var.server_port
  instance_type      = "t2.nano"
  rendered_user_data = module.webapp.rendered_user_data  # Change me

  # Autoscaling group arguments
  min_instance    = 2
  max_instance    = 4
}
```

2. Don't forget to update your outputs. Namely, the `debian_ami_id` output.

</details>


### Upgrading your modules

You will now upgrade your modules to version `v0.2.0`.
* The `webapp` module now return a webpage with 
  * The random pet name from terraform
  * A random pet name generated during the instance initialisation
* The `cluster` module will now refresh automatically instances upon changes of the `webapp`.
  
To upgrade your modules
1. Replace in both module sources the tag `v0.1.0` by `v0.2.0`
2. Add the new argument `instance_warmup` to the `cluster` module, i.e.,
    ```HCL
    module "cluster" {
      source = "github.com/meyerx/terraform-example-modules.git//modules/cluster?ref=v0.2.0"
    
      ... # Other arguments
      
      # Autoscaling group arguments
      min_instance    = 2
      max_instance    = 4
      instance_warmup = 15 # Making instance refreshes faster
    }
    ```
3. Init, plan and apply your recipe.
4. Check what is happening over the next 2-3 minutes on your [AWS console](https://eu-west-1.console.aws.amazon.com/ec2/v2/home?region=eu-west-1#Home:). 
   * What happens if you access and refresh your webpage now? 
   * *Tip 1: Reuse the previous shell commands.*
   * *Tip 2: This may take a few minute. Launch the command and go grab a coffee.*

## Leads for further exploration

* Play around with meta-arguments
* Browse the Terraform registry for modules that could be useful to your projects

## Troubleshooting
You can look for the solution of this practical in `tutorials/solutions/TP5`.
