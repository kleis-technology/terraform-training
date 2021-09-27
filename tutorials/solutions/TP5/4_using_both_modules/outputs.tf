
output "debian_ami_id" {
  value = module.webapp.ami_id
}

output "alb_dns_name" {
  value       = module.cluster.alb_dns_name
  description = "The domain name of the load balancer"
}

output "asg_name" {
  value       = module.cluster.asg_name
  description = "The name of the Auto Scaling Group"
}
