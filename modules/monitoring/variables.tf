# ./modules/monitorings/variables.tf
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
}

# Tags for Resource Identification
variable "tags" {
  description = "Labels/tags to apply to resources."
  type        = map(string)
}


variable "k8s_namespace" {
  description = "Kubernetes namespace where the application is deployed"
  type        = string
}

variable "hpa_cpu_alert_threshold" {
  description = "CPU threshold for HPA"
  type        = number
}

variable "alert_email_address" {
  description = "Email address to receive monitoring alerts"
  type        = string
}