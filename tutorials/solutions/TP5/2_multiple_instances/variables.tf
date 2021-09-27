variable "ssh_key_name" {
  type        = string
  description = "Name of the aws key-pair assigned to this user."
}

variable "cattle_names" {
  description = "Cattle names."
  type        = list(string)
  default = [
    "mighty_panda",
    "giant_owl",
    "cute_beaver"
  ]
}
