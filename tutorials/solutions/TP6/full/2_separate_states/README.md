# Solution B: One folder per states

## Description

In this solution, we use a separate folder for each environment.

### Advantages
* Environments are strongly isolated
    * Yet they reuse the same core modules
* Environments can differ significantly without needing to use complex conditional statements

### Disadvantages
* This code is potentially less *DRY* when environments share significant portions of code
    * E.g., backend state