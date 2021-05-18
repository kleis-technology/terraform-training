# Solution C: Using Terraform workspace

## Description

In this solution, we use Terraform Workspaces.

### Advantages

- Environments are strongly isolated
  - But the backend location must be the same (e.g., same AWS S3 bucket)
- DRY principle

### Disadvantages

- Requires to choose a strategy for the specialisation
  - Using different variable files specified manually
  - Using hardcoded conditional statements in the recipe
  - Etc.
- Only one workspace is active at a time (per local folder)

## How it works

### Customize the S3 path for each state

The `backend.tfvars` must be modified to include the `workspace_key_prefix`argument.

```HCL
  # Add for instance,
  workspace_key_prefix = "kleis-sandbox/training/remote_state/MY_USERNAME/full_3

```

This will define the key leading to the state of each workspace.
The final location of the state will be the `workspace_key_prefix` postfixed with a new folder having the workspace name, and the state file name.

### Specialize the behavior of your recipe as a function of the workspace

In this example, we are using a yaml file containing the configurations for each workspace.
The recipe then look into the map defined in the yaml to retrieve the configuration for the current workspace using the `terraform.workspace` attribute.

### Using workspace

1. Create your workspaces

```bash
> terraform workspace new test
> terraform workspace new stage
> terraform workspace new prod
```

2. Select a workspace and init, plan and apply your recipe

```bash
> terraform workspace select prod
> terraform init -backend-config="backend.tfvars"
> # etc...
```

### Fast (but unsafe) cleanup

```bash
for wp in `terraform workspace list`
do
  if [ ${wp} != "*" ]
  then
    echo "Destroying $wp"
    terraform workspace select ${wp}
    terraform destroy -var "ssh_key_name=<YOUR_KEY_NAME>" -auto-approve
  fi
done
```
