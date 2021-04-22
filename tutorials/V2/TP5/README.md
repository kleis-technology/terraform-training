# Using Meta-Arguments and External Modules

In this practical, we will see how to use meta-arguments to create multiple resources and how to call modules from our recipe.

### Goal

* Interact with meta-arguments
* Import external modules stored on a Git repository

### Context

We restart from the recipe built in the previous practical.

#### Setting/resetting recipe
<details>
  <summary>Click here if you need to init/reset your configuration.</summary>

1. Destroy your previous terraform configuration if you had one
```bash
terraform destroy
```
2. Copy the content of `tutorials/V2/solutions/TP4/SecondPhase` in your working directory and apply the configuration.
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

* Add a new boolean variable named `withHTTP`.
  * If `withHTTP==0` then your instance will only accept ssh connections.
  * Else the instance will accept ssh connections and serve a webpage.
* *Hint: think about [the meta-argument `count`](https://www.terraform.io/docs/language/meta-arguments/count.html) and [the ternary operator](https://www.terraform.io/docs/language/expressions/conditionals.html)*.

#### Solution
<details>
  <summary>Click here to see.</summary>

1. Duplicate and modify your `aws_instance`(s).
```hcl
resource "aws_instance" "only_ssh_vm" {
  # Create one instance if var.withHTTP is set to false
  count                       = var.withHTTP ? 0 : 1
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
  count                       = var.withHTTP ? 1 : 0
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
</details>

### Multiple instances with different configurations

In this scenario, you will create multiple virtual machines with different configurations.

Let's assume that our scripts takes as input variables mapping the virtual machine name with its configuration script.
For instance,
```hcl
variable "cattle" {
  description = "Configuration scripts for cattle."
  type = map(string)
  default = {
    mighty_panda = "scripts/mighty_panda_config.sh"
    giant_owl = "scripts/giant_owl_config.sh"
    cute_beaver = "scripts/cute_beaver_config.sh"
  }
}
```
Using this map, we would want to initialize multiple virtual machine configured by their respective scripts.
* Re-use the `template_file` and `aws_instance` resources.
  * Don't duplicate them.
  * *Hint: Think about *for-like* statements supported by HCL.*

#### Tips
Using *for-like* statements is very useful to declare list of users or roles.

#### Solution
<details>
  <summary>Click here to see.</summary>

1. Use [a `for_each` meta-argument](https://www.terraform.io/docs/language/meta-arguments/for_each.html), for instance.
2. Modify your  `template_file` and `aws_instance` resources.
```hcl
data "template_file" "webservers" {
  for_each = var.cattle

  template = file(each.value)

  vars = {
    server_port = var.server_port
  }
}

resource "aws_instance" "webservers" {  
  for_each                    = var.cattle
  
  ami                         = data.aws_ami.debian_buster.id
  instance_type               = "t2.nano"
  key_name                    = var.ssh_key_name
  subnet_id                   = data.terraform_remote_state.training.outputs.subnet_id
  vpc_security_group_ids      = [data.terraform_remote_state.training.outputs.vm_security_group_id]
  associate_public_ip_address = true
  user_data                   = data.template_file.webservers[var.key].rendered
  tags = {
    Name = "kleis-training-webserver-${each.key}"
  }
}
```
</details>




## Concept
* Call a module on a git repository
  * Load balancing, multiple instance
  * Input VPC, subnet, VM info: ami, script, etc.
  * Call
* Create a module using current recipe
* Call it multiple time from another recipe?

