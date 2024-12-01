
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
  description = "Maximum number of nodes nodes per zone in the GKE node pool."
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

