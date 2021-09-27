# Refactoring or fixing drifting configurations

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
   