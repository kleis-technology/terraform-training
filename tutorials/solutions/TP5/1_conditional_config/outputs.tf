
output "debian_ami_id" {
  value = data.aws_ami.debian_latest.id
}

output "vm_ip" {
  value = "%{if var.with_webpage}${aws_instance.webserver_vm[0].public_ip}%{else}${aws_instance.only_ssh_vm[0].public_ip}%{endif}"
}
