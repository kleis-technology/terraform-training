output "webservers" {
  description = "The IP or load balancer URL for each environments."
  value = {
    for key, values in local.environments : key => module.demo_webapp[key].webserver_info
  }
}
