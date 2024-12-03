

# =========================================
# Kubernetes Outputs
# =========================================

## WordPress Application Outputs

# URL for accessing the WordPress application
output "wordpress_url" {
  description = "URL for the WordPress website."
  value       = "https://${var.wordpress_ip_address}/"
}

## Namespace Outputs

# Name of the Kubernetes namespace created for the application
output "kubernetes_namespace" {
  description = "Name of the Kubernetes namespace."
  value       = kubernetes_namespace.wordpress.metadata[0].name
}

## Deployment Outputs

# # Name of the WordPress Deployment
# output "wordpress_deployment_name" {
#   description = "Name of the WordPress Deployment."
#   value       = kubernetes_deployment.wordpress.metadata[0].name
# }

# # Replica count of the WordPress Deployment
# output "wordpress_deployment_replicas" {
#   description = "Replica count of the WordPress Deployment."
#   value       = kubernetes_deployment.wordpress.spec[0].replicas
# }

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

# # Name of the Horizontal Pod Autoscaler
# output "wordpress_hpa_name" {
#   description = "Name of the Horizontal Pod Autoscaler."
#   value       = kubernetes_horizontal_pod_autoscaler.wordpress_hpa.metadata[0].name
# }

# # Minimum replicas managed by the HPA
# output "wordpress_hpa_min_replicas" {
#   description = "Minimum replicas managed by the Horizontal Pod Autoscaler."
#   value       = kubernetes_horizontal_pod_autoscaler.wordpress_hpa.spec[0].min_replicas
# }

# # Maximum replicas managed by the HPA
# output "wordpress_hpa_max_replicas" {
#   description = "Maximum replicas managed by the Horizontal Pod Autoscaler."
#   value       = kubernetes_horizontal_pod_autoscaler.wordpress_hpa.spec[0].max_replicas
# }

# # Target CPU utilization percentage of the HPA
# output "wordpress_hpa_target_cpu_utilization" {
#   description = "Target CPU utilization percentage for the Horizontal Pod Autoscaler."
#   value       = kubernetes_horizontal_pod_autoscaler.wordpress_hpa.spec[0].target_cpu_utilization_percentage
# }

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

# ------------------------------------------------------------------------

output "db_secret_name" {
  value = kubernetes_secret.db_credentials.metadata[0].name
}

output "db_secret_namespace" {
  value = kubernetes_secret.db_credentials.metadata[0].namespace
}

