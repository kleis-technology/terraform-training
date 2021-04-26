output "webserver_info" {
  description = "The public IP of the test webserver if max_instance == 1, else the domain name of the load balancer."
  value = var.max_instance > 1 ? module.cluster[0].alb_dns_name : aws_instance.webserver[0].public_ip
}

