# Creating your own module

In this last practical, we will see how to create your own module and use it to provision environments for testing and deploying your "web application".

### Goal

- Create your own module
- Use it to provision several environments
- (Opt) Try Terraform commands to fix drifts

### Context

Restart from the recipe built in the previous practical.

#### Setting/resetting recipe

<details>
  <summary>Click here if you need to init/reset your configuration.</summary>

1. Destroy your previous terraform configuration if you had one

```bash
terraform destroy
```

2. Copy the content of `tutorial/solutions/TP5/4_using_both_modules` in your working directory and apply the configuration.

```bash
# if not done previously
terraform init
# Use your key name
terraform plan -out terraform.tfplan
# if ok, apply (replace YOUR_KEY_NAME)
terraform apply terraform.tfplan
```

</details>

## Creating a module

Congratulations, you have reached the last practical!

In this practical, you are asked to

1. Adapt the current recipe to allow for a parametrization of the amount of resources provisioned, e.g.,
   - A single instance without autoscaling group and load balancer
   - Varying ranges of instances for the autoscaling group
2. Create a module from the resulting recipe.
   - _Tips: Don't forget that modules need to have a README.md file._
3. Use this module to create multiple environments
   - A `test` environment with a single instance
   - A `pre-prod` environment with limited resources in the autoscaling group (e.g., `min=2`, `max=4`)
   - A `prod` environment with more resources in the autoscaling group (e.g., `min=2`, `max=8`)

There isn't a unique way to reach this end goal.
Think about the downsides and advantages of each of them.

####Tips

- Think about conditional expressions (i.e., ternary operators)
- Think about how many recipes you will have at end.
  - _A single one? One per environments?_
  - What will be the impact on the environments isolation and the state?

## Refactoring or fixing drifting configurations (Optional)

Sometimes, it may be required to alter the state of a configuration by importing, moving or removing resources.

This can be achieved by using terraform commands:

- [The command `terraform import`](https://www.terraform.io/docs/cli/import/index.html) import existing infrastructure into the state.
- [The command `terraform mv`](https://www.terraform.io/docs/cli/commands/state/mv.html) to move infrastructure within or across states
- [The command `terraform rm`](https://www.terraform.io/docs/cli/commands/state/rm.html) to remove infrastructure from the state.

### Scenario A: Refactoring

1. Try renaming a resource using the `terraform mv`
2. If you have multiple environments, try moving a resources between two states.

### Scenario B: Fixing conflicting states

Starting from a recipe with a single instance.

1. Use the [AWS console](https://eu-west-1.console.aws.amazon.com/ec2/v2/home?region=eu-west-1#Home:) to terminate your instance.
2. What happens when you try to interact with your state?
3. Fix the issue using `terraform rm`.
4. Now, relaunch the instance using the [AWS console](https://eu-west-1.console.aws.amazon.com/ec2/v2/home?region=eu-west-1#Home:).
5. Import this infrastructure using the `terraform import` command.
   - _Tips: Each provider documentation defines how to import resources (e.g., [aws_instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance#import))._

## Solution

You can look for a possible solution for the multiple environments setting in `tutorials/solutions/TP6`.
