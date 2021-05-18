variable "ssh_key_name" {
  type        = string
  description = "Name of the aws key-pair assigned to this user."
}

variable "with_webpage" {
  description = "Boolean defining if the a webpage is served."
  type        = bool
}

variable "server_port" {
  type        = number
  description = "VM port listening for TCP connections."
  default     = 8000
}
