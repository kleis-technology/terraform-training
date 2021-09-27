output "webserver" {
  description = "The IP or load balancer URL of your webserver(s)."
  value       = module.demo_webapp.webserver_info
}
