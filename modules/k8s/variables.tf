# ./modules/k8s/variables.tf
# root module variables 
# Resource Naming Prefix
variable "prefix" {
  description = "Prefix for naming resources."
  type        = string
  default     = "wordpress"
}

# Project and Region Configuration
variable "project_id" {
  description = "GCP project ID where resources will be created."
  type        = string
}

variable "region" {
  description = "GCP region for resource deployment."
  type        = string
  default     = "me-west1"
}
# Tags for Resource Identification
variable "tags" {
  description = "Labels/tags to apply to resources."
  type        = map(string)
  default = {
    "managed-by"  = "terraform"
    "team"        = "devops"
    "environment" = "test"
  }
}


# Namespace Configuration
variable "namespace" {
  description = "Kubernetes namespace."
  type        = string
  default     = "wordpress-app"
}

# WordPress Deployment Configuration
variable "wordpress_image" {
  description = "Docker image for WordPress."
  type        = string
  default     = "wordpress"
}

variable "wordpress_tag" {
  description = "Image tag for WordPress."
  type        = string
  default     = "latest"
}

variable "replica_count" {
  description = "Initial number of WordPress pod replicas."
  type        = number
  default     = 2
}

# Horizontal Pod Autoscaler Configuration
variable "hpa_min_replicas" {
  description = "Minimum number of replicas for Horizontal Pod Autoscaler."
  type        = number
  default     = 2
}

variable "hpa_max_replicas" {
  description = "Maximum number of replicas for Horizontal Pod Autoscaler."
  type        = number
  default     = 10
}

variable "hpa_cpu_utilization" {
  description = "Target average CPU utilization for HPA."
  type        = number
  default     = 70
}

# PVC Storage Configuration
variable "pvc_storage_class" {
  description = "Storage class for Persistent Volume Claims."
  type        = string
  default     = "standard"
}

variable "pvc_storage_size" {
  description = "Storage size for Persistent Volume Claim (Gi)."
  type        = string
  default     = "20Gi"
}


variable "wordpress_db_instance_name" {
  description = "Name of the Cloud SQL instance."
  type        = string
  default     = "your-sql-instance-name"
}

variable "wordpress_db_user" {
  description = "Database user for the application."
  type        = string
}

variable "wordpress_db_password" {
  description = "Password for the database user (Sensitive)."
  type        = string
  sensitive   = true
}

variable "wordpress_db_connection_name" {
  description = "Connection name for Cloud SQL (used by GKE)."
  type        = string
}

variable "wordpress_db_ip" {
  description = "Private IP address of the Cloud SQL instance."
  type        = string
}

# WordPress Database Variables

variable "wordpress_db_name" {
  description = "Name of the WordPress database."
  type        = string
}

# Global IP Variables

variable "wordpress_ip_address" {
  description = "Global IP address allocated for the WordPress ingress."
  type        = string
}


variable "wordpress_ip_address_name" {
  description = "Global IP address allocated for the WordPress ingress."
  type        = string
}




