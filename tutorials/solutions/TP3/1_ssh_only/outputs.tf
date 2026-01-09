
output "debian_ami_id" {
  value = data.aws_ami.debian_latest.id
}

output "vm_ip" {
  value = aws_instance.vm.public_ip
}
