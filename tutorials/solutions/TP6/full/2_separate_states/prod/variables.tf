# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------


variable "ssh_key_name" {
  description = "Name of the aws key-pair assigned to this user"
  type        = string
}

variable "server_port" {
  description = "The name to use for all the cluster resources"
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
