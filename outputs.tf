output "wordpress_url" {
  description = "URL for the WordPress website."
  value       = module.k8s_deployment.wordpress_url
}

output "wordpress_db_instance_name" {
  value = module.gcp_infrastructure.db_instance_name
}

output "wordpress_db_user" {
  value = module.gcp_infrastructure.db_user
}

output "wordpress_db_connection_name" {
  value = module.gcp_infrastructure.db_connection_name
}

output "wordpress_db_ip" {
  value = module.gcp_infrastructure.db_ip
}

output "wordpress_db_name" {
  value = module.gcp_infrastructure.wordpress_db_name
}
