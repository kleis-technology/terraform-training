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

Let's assume that our configuration script has different behaviors in function of its assigned virtual machine name.
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

One of the main guiding principle of IaC is to be able to reuse, import, and share part of your code
In Terraform, this principle is mostly unlocked by the use of modules.

In this exercise, we will use two example modules from a Git repository.

### Trading the AWS instance by an AWS autoscaling group with load balancer


#### Solution
<details>
  <summary>Click here to see.</summary>

1. titi
```hcl
toto
```
</details>

### Replacing the image configuration by an external module

#### Solution
<details>
  <summary>Click here to see.</summary>

1. titi
```hcl
toto
```
</details>