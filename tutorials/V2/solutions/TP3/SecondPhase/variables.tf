variable "ssh_key_name" {
  type = string
  description = "Name of the aws key-pair assigned to this user."
}

variable "subnet" {
  type = string
  description = "ID of the AWS subnet declared in the VPC."
}

variable "vpc_security_groups" {
  type = list
  description = "ID(s) of the security groups associated with the VPC."
}

variable "server_port" {
  type = number
  description = "VM port listening for TCP connections."
  default = 8000
}

