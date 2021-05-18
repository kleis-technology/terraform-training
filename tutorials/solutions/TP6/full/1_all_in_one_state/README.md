# Solution A: All in one state

## Description

In this solution, we use a single recipe to provision 3 environment.

### Advantages

- DRY principle (_don't repeat yourself_)

### Disadvantages

- The environments are not strongly isolated
  - One Terraform state for all env.
  - One folder/repository for all env.
- Hardly applicable when environments are significantly different
