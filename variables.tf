# =========================================
# Shared Variables
# =========================================

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
  description = "Minimum number of nodes in the GKE node pool."
  type        = number
  default     = 1
}

variable "max_node_count" {
  description = "Maximum number of nodes in the GKE node pool."
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

# =========================================
# Commented Variables for Outputs
# =========================================

# Uncomment and set these variables if you want to override the default values or manage them explicitly.

# Cloud SQL Instance Variables

# variable "db_instance_name" {
#   description = "Name of the Cloud SQL instance."
#   type        = string
#   default     = "your-sql-instance-name"
# }

# variable "db_user" {
#   description = "Database user for the application."
#   type        = string
#   default     = "your-database-user"
# }

# variable "db_password" {
#   description = "Password for the database user (Sensitive)."
#   type        = string
#   default     = "your-database-password" # Replace with a secure value or leave unset for Terraform to generate one.
# }

# variable "db_connection_name" {
#   description = "Connection name for Cloud SQL (used by GKE)."
#   type        = string
#   default     = "your-connection-name"
# }

# variable "db_ip" {
#   description = "Private IP address of the Cloud SQL instance."
#   type        = string
#   default     = "your-database-private-ip"
# }

# WordPress Database Variables

# variable "wordpress_db_name" {
#   description = "Name of the WordPress database."
#   type        = string
#   default     = "wordpress"
# }

# Global IP Variables

# variable "wordpress_ip_address" {
#   description = "Global IP address allocated for the WordPress ingress."
#   type        = string
#   default     = "your-global-ip-address"
# }
