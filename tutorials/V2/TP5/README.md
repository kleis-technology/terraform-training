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

Meta-Arguments


## Concept
* Call a module on a git repository
  * Load balancing, multiple instance
  * Input VPC, subnet, VM info: ami, script, etc.
  * Call
* Create a module using current recipe
* Call it multiple time from another recipe?

