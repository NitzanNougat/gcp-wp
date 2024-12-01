# =========================================
# GCP Outputs
# =========================================

## VPC Network Outputs

# Name of the created VPC network
output "vpc_network_name" {
  description = "Name of the created VPC network."
  value       = google_compute_network.vpc_network.name
}

# Name of the created subnet
output "subnet_name" {
  description = "Name of the created subnet."
  value       = google_compute_subnetwork.private_subnet.name
}

# Self link of the VPC network
output "vpc_network_self_link" {
  description = "Self link of the VPC network."
  value       = google_compute_network.vpc_network.self_link
}

# Self link of the subnet
output "subnet_self_link" {
  description = "Self link of the subnet."
  value       = google_compute_subnetwork.private_subnet.self_link
}

## GKE Cluster Outputs

# Name of the GKE cluster
output "gke_cluster_name" {
  description = "Name of the GKE cluster."
  value       = google_container_cluster.primary.name
}

# Endpoint of the GKE cluster
output "gke_cluster_endpoint" {
  description = "Endpoint of the GKE cluster."
  value       = google_container_cluster.primary.endpoint
}

# Master version of the GKE cluster
output "gke_cluster_master_version" {
  description = "Master version of the GKE cluster."
  value       = google_container_cluster.primary.master_version
}

# Location of the GKE cluster
output "gke_cluster_location" {
  description = "Location of the GKE cluster."
  value       = google_container_cluster.primary.location
}

# Name of the GKE node pool
output "node_pool_name" {
  description = "Name of the GKE node pool."
  value       = google_container_node_pool.primary_nodes.name
}

## Cloud SQL Outputs

# Name of the Cloud SQL instance
output "db_instance_name" {
  description = "Name of the Cloud SQL instance."
  value       = google_sql_database_instance.mysql_instance.name
}

# Database user for the application
output "db_user" {
  description = "Database user for the application."
  value       = google_sql_user.db_user.name
}

# Password for the database user (Sensitive)
output "db_password" {
  description = "Password for the database user (Sensitive)."
  value       = random_password.db_password.result
  sensitive   = true
}

# Connection name for Cloud SQL (used by GKE)
output "db_connection_name" {
  description = "Connection name for Cloud SQL (used by GKE)."
  value       = google_sql_database_instance.mysql_instance.connection_name
}

# Private IP address of the Cloud SQL instance
output "db_ip" {
  description = "Private IP address of the Cloud SQL instance."
  value       = google_sql_database_instance.mysql_instance.private_ip_address
}

# Name of the WordPress database
output "wordpress_db_name" {
  description = "Name of the WordPress database."
  value       = google_sql_database.wordpress_db.name
}

## Global IP Outputs

# Global IP address allocated for the WordPress ingress
output "wordpress_ip_address" {
  description = "Global IP address allocated for the WordPress ingress."
  value       = google_compute_global_address.wordpress_ip.address
}

# =========================================
# Kubernetes Outputs
# =========================================

## WordPress Application Outputs

# URL for accessing the WordPress application
output "wordpress_url" {
  description = "URL for the WordPress website."
  value       = "https://${google_compute_global_address.wordpress_ip.address}/"
}
