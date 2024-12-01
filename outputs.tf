output "wordpress_url" {
  description = "URL for the WordPress website."
  value       = module.k8s_deployment.wordpress_url
}