# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------


variable "ssh_key_name" {
  description = "Name of the aws key-pair assigned to this user"
  type        = string
}
