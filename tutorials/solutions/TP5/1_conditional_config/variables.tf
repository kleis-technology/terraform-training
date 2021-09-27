variable "ssh_key_name" {
  type        = string
  description = "Name of the aws key-pair assigned to this user."
}

variable "with_webpage" {
  description = "Boolean defining if the a webpage is served."
  type        = bool
}
