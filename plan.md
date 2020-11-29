# Terraform Training

## Infrastructure as Code

### Motivations
- avoiding human errors
- scalability
- pets vs. cattle
- reuse
- conformity
- uniformity
- versioning
- sharing
- modularity
- idempotency
- drift detection / correction, state validation
- self-documented
- central view on configuration

### IaC Tools and their Scope
- configuration management (Ansible, Puppet, Chef...)
  * host management
  * with or without an agent
- infrastructure provisioning (Terraform, Pulumi, Cloudformation...)
  * cloud providers
  * API based

### IaC Principles
- desired state
- current state
- difference computation
- action plan
- execution

## Terraform

### Base Concepts
- providers
- state
- HCL
- resources
- data sources

### State
- desired state expressed by HCL code
- resources created by Terraform stored in the state
- reality may be different, things not managed by code are not tracked

### State Storage
- local
- remote
- locking

### Providers
- configuration
- resources
- data sources

### Resources
- arguments
- attributes
- importing resources
- in-place modifications / replacement

### Data Sources
- retrieving information from reality
- arguments
- attributes

### Variables and Outputs
- analogy with parameters and outputs of functions
- declaring variables
  * types
- providing values for variables
  * `tfvars` files
  * command line parameters
  * environment variables
- local variables
- declaring outputs
- accessing outputs values from state

### Dependencies
- implicit
- explicit
- graph

### Modules
- local
- from outside sources
- interface through variables and outputs

### Remote States

### Loops
- count
- for_each

### Conditionals
- ternary (a.k.a. Elvis) operator
- count trick

### HCL Types
- strings
- numbers
- booleans
- lists
- sets
- maps
- objects
- tuples

### HCL Utility Functions
