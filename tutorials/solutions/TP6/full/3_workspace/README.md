* Using workspace
* Require same remote_backend but different states
* Unclear about is the setting of each workspace
    * Hardcoded? 
    * Yaml'd?
    * Inputs?
* You can only have one workspace active at the same time (per local folder)
  
## Todo

* Add `workspace_key_prefix = "kleis-sandbox/training/remote_state/XME/full_3"` in remote state
* Use yaml in the example


* Commands to create workspaces
> terraform workspace list

> terraform workspace new test

> terraform workspace new stage

> terraform workspace new prod


## Lazy cleanup
```bash
for wp in `terraform workspace list`
do 
  if [ ${wp} != "*" ]
  then 
    echo "Destroying $wp"
    terraform workspace select ${wp}
    terraform destroy -var "ssh_key_name=xme" -auto-approve
  fi
done
```