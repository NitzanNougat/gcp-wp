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




# =========================================
# Kubernetes Module Outputs (For Future Use)
# =========================================

## Namespace Outputs

# Name of the Kubernetes namespace created for the application
output "kubernetes_namespace" {
  description = "Name of the Kubernetes namespace."
  value       = kubernetes_namespace.wordpress.metadata[0].name
}

## Deployment Outputs

# Name of the WordPress Deployment
output "wordpress_deployment_name" {
  description = "Name of the WordPress Deployment."
  value       = kubernetes_deployment.wordpress.metadata[0].name
}

# Replica count of the WordPress Deployment
output "wordpress_deployment_replicas" {
  description = "Replica count of the WordPress Deployment."
  value       = kubernetes_deployment.wordpress.spec[0].replicas
}

## Service Outputs

# Name of the WordPress Service
output "wordpress_service_name" {
  description = "Name of the WordPress Service."
  value       = kubernetes_service.wordpress.metadata[0].name
}

# Cluster IP of the WordPress Service
output "wordpress_service_cluster_ip" {
  description = "Cluster IP of the WordPress Service."
  value       = kubernetes_service.wordpress.spec[0].cluster_ip
}

# NodePort for the WordPress Service (if applicable)
output "wordpress_service_node_port" {
  description = "NodePort for the WordPress Service (if applicable)."
  value       = kubernetes_service.wordpress.spec[0].port[0].node_port
}

## Persistent Volume Outputs

# Name of the Persistent Volume for WordPress shared storage
output "wordpress_pv_name" {
  description = "Name of the Persistent Volume for WordPress shared storage."
  value       = kubernetes_persistent_volume.wordpress_shared.metadata[0].name
}

# Capacity of the Persistent Volume
output "wordpress_pv_capacity" {
  description = "Capacity of the Persistent Volume."
  value       = kubernetes_persistent_volume.wordpress_shared.spec[0].capacity["storage"]
}

## Persistent Volume Claim Outputs

# Name of the Persistent Volume Claim for WordPress shared storage
output "wordpress_pvc_name" {
  description = "Name of the Persistent Volume Claim for WordPress shared storage."
  value       = kubernetes_persistent_volume_claim.wordpress_shared.metadata[0].name
}

# Storage class name of the PVC
output "wordpress_pvc_storage_class" {
  description = "Storage class name of the Persistent Volume Claim."
  value       = kubernetes_persistent_volume_claim.wordpress_shared.spec[0].storage_class_name
}

## Horizontal Pod Autoscaler Outputs

# Name of the Horizontal Pod Autoscaler
output "wordpress_hpa_name" {
  description = "Name of the Horizontal Pod Autoscaler."
  value       = kubernetes_horizontal_pod_autoscaler.wordpress_hpa.metadata[0].name
}

# Minimum replicas managed by the HPA
output "wordpress_hpa_min_replicas" {
  description = "Minimum replicas managed by the Horizontal Pod Autoscaler."
  value       = kubernetes_horizontal_pod_autoscaler.wordpress_hpa.spec[0].min_replicas
}

# Maximum replicas managed by the HPA
output "wordpress_hpa_max_replicas" {
  description = "Maximum replicas managed by the Horizontal Pod Autoscaler."
  value       = kubernetes_horizontal_pod_autoscaler.wordpress_hpa.spec[0].max_replicas
}

# Target CPU utilization percentage of the HPA
output "wordpress_hpa_target_cpu_utilization" {
  description = "Target CPU utilization percentage for the Horizontal Pod Autoscaler."
  value       = kubernetes_horizontal_pod_autoscaler.wordpress_hpa.spec[0].target_cpu_utilization_percentage
}

## Ingress Outputs

# Name of the WordPress Ingress resource
output "wordpress_ingress_name" {
  description = "Name of the WordPress Ingress resource."
  value       = kubernetes_ingress_v1.wordpress_ingress.metadata[0].name
}

# TLS Secret name used by the Ingress
output "wordpress_ingress_tls_secret_name" {
  description = "TLS Secret name used by the Ingress."
  value       = kubernetes_ingress_v1.wordpress_ingress.spec[0].tls[0].secret_name
}

# Default backend service used by the Ingress
output "wordpress_ingress_backend_service_name" {
  description = "Default backend service used by the Ingress."
  value       = kubernetes_ingress_v1.wordpress_ingress.spec[0].default_backend[0].service[0].name
}
