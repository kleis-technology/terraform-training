# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------

# General input
variable "environment_name" {
  description = "Name of the environment."
  type        = string
}

# Network inputs
variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "subnet_ids" {
  description = "IDs of the AWS subnet declared in the VPC"
  type        = list(any)
  validation {
    condition     = length(var.subnet_ids) <= 2
    error_message = "There must be at least 2 subnets having different availability zones."
  }
}

variable "vpc_security_group_ids" {
  description = "IDs of the security groups associated with the VPC"
  type        = list(any)
}

# Instance inputs
variable "ssh_key_name" {
  description = "Name of the aws key-pair assigned to this user."
  type        = string
}

variable "server_port" {
  description = "VM port listening for TCP connections."
  type        = number
  default     = 8000
}

# Cluster inputs
variable "min_instance" {
  description = "Minimum number of instances in the cluster."
  type        = number
}

variable "max_instance" {
  description = "Maximum number of instances in the cluster."
  type        = number
}

