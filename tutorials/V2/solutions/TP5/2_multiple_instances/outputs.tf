
output "debian_ami_id" {
  value = data.aws_ami.debian_buster.id
}

output "vm_ips" {
  value = tomap({
    for name, webserver in aws_instance.webservers : name => webserver.public_ip
  })
}