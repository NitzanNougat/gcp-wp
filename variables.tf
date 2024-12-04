# =========================================
# Shared Variables
# =========================================
# variables.tf
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

# Resource Naming Prefix
variable "prefix" {
  description = "Prefix for naming resources."
  type        = string
  default     = "wordpress"
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

# =========================================
# GCP-Specific Variables
# =========================================

# VPC and Subnet Configuration
variable "vpc_cidr" {
  description = "CIDR block for the custom VPC network."
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr_cluster" {
  description = "CIDR block for the subnet within the VPC."
  type        = string
  default     = "10.0.1.0/24"
}

variable "cidr_range_sql" {
  description = "CIDR block for the SQL network range."
  type        = string
  default     = "10.0.3.0/24"
}

# GKE Node Pool Configuration
variable "machine_type" {
  description = "Machine type for GKE nodes."
  type        = string
  default     = "e2-medium"
}

variable "disk_type" {
  description = "Disk type for GKE nodes."
  type        = string
  default     = "pd-balanced"
}

variable "disk_size_gb" {
  description = "Disk size for GKE nodes (GB)."
  type        = number
  default     = 15
}

variable "min_node_count" {
  description = "Minimum number of nodes per zone in the GKE node pool."
  type        = number
  default     = 1
}

variable "max_node_count" {
  description = "Maximum number of nodes nodes per zonein the GKE node pool."
  type        = number
  default     = 3
}

# Database Configuration
variable "db_tier" {
  description = "The tier (machine type) for the Cloud SQL instance."
  type        = string
  default     = "db-f1-micro"
}

variable "db_version" {
  description = "The database version for the Cloud SQL instance."
  type        = string
  default     = "MYSQL_8_0"
}

# Alerting Configuration
variable "alert_email" {
  description = "Email address to send alert notifications."
  type        = string
}

variable "db_delete_protection" {
  description = "True for db instance to have delete protection within terraform"
  type        = bool
  default     = true
}

# =========================================
# Kubernetes-Specific Variables
# =========================================

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

variable "cluster_delete_protection" {
  description = "True for cluster to have delete protection within terraform"
  type        = bool
  default     = true
}