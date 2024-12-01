#-------------------data----------------

data "google_client_config" "default" {}

# Retrieve cluster credentials
data "google_container_cluster" "primary" {
  name     = google_container_cluster.primary.name
  location = var.region
  project  = var.project_id
}



# Locals Block
locals {
  required_services = [
    "compute.googleapis.com",              # Compute Engine API
    "container.googleapis.com",            # Kubernetes Engine API
    "sqladmin.googleapis.com",             # Cloud SQL API
    "iam.googleapis.com",                  # IAM API
    "cloudresourcemanager.googleapis.com", # Cloud Resource Manager API
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "servicenetworking.googleapis.com",
    "file.googleapis.com"
  ]

  # Firewall tags
  firewall_gke_tag = "${var.prefix}-gke-nodes"
  firewall_db_tag  = "${var.prefix}-cloudsql-db"

  # Split the CIDR into address and prefix length
  sql_cidr_parts = split("/", var.cidr_range_sql)

  # Extract the base address (e.g., "10.0.3.0")
  sql_cidr_address = local.sql_cidr_parts[0]

  # Extract the prefix length as a number (e.g., 24)
  sql_cidr_prefix_length = tonumber(local.sql_cidr_parts[1])

}


# Enable Relevant APIs
resource "google_project_service" "required_services" {
  for_each = toset(local.required_services)
  project  = var.project_id
  service  = each.value

}


# Create a custom VPC network
resource "google_compute_network" "vpc_network" {
  name                    = "${var.prefix}-vpc"
  auto_create_subnetworks = false
  project                 = var.project_id
  depends_on = [google_project_service.required_services]
}

# Create a private subnet within the VPC
resource "google_compute_subnetwork" "private_subnet" {
  name                     = "${var.prefix}-private-subnet"
  ip_cidr_range            = var.subnet_cidr_cluster
  network                  = google_compute_network.vpc_network.self_link
  region                   = var.region
  private_ip_google_access = true
  project                  = var.project_id

}


# Define firewall rules
resource "google_compute_firewall" "allow_internal" {
  name    = "${var.prefix}-allow-internal"
  network = google_compute_network.vpc_network.self_link

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = ["10.0.0.0/16"]
  target_tags   = ["internal"]
  project       = var.project_id
}

resource "google_compute_firewall" "allow_ssh" {
  name    = "${var.prefix}-allow-ssh"
  network = google_compute_network.vpc_network.self_link

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ssh"]
  project       = var.project_id
}

resource "google_compute_firewall" "allow_http_https" {
  name    = "${var.prefix}-allow-http-https"
  network = google_compute_network.vpc_network.self_link

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web"]
  project       = var.project_id
}

resource "google_compute_firewall" "allow_sql_access_ingress" {
  name    = "${var.prefix}-allow-sql-access-ingress"
  network = google_compute_network.vpc_network.self_link

  # By Default
  direction = "INGRESS"

  # Allow traffic from GKE nodes
  source_tags = [local.firewall_gke_tag]

  # Target the Cloud SQL reserved range
  destination_ranges = [var.cidr_range_sql]

  allow {
    protocol = "tcp"
    ports    = ["3306"] # MySQL default port
  }

  project = var.project_id
}

# Create the GKE cluster
resource "google_container_cluster" "primary" {
  name     = "${var.prefix}-cluster"
  location = var.region

  network    = google_compute_network.vpc_network.name
  subnetwork = google_compute_subnetwork.private_subnet.name

  remove_default_node_pool = true
  initial_node_count       = 1

  # Logging and Monitoring
  logging_service    = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"
}

# Create a node pool with autoscaling
resource "google_container_node_pool" "primary_nodes" {
  name     = "${google_container_cluster.primary.name}-node-pool"
  location = var.region
  cluster  = google_container_cluster.primary.name
  project  = var.project_id

  node_count = var.min_node_count


  autoscaling {
    min_node_count = var.min_node_count
    max_node_count = var.max_node_count
  }

  node_config {
    machine_type = var.machine_type
    # Tags to apply firewall rules
    tags         = [local.firewall_gke_tag]
    disk_type    = var.storage_class
    disk_size_gb = var.disk_size_gb

  }
}

# Service Account for GKE Nodes
resource "google_service_account" "gke_nodes" {
  account_id   = "${var.prefix}-gke-node-sa"
  display_name = "GKE Node Service Account"
  project      = var.project_id
}

# Grant necessary IAM roles to the node service account
resource "google_project_iam_member" "gke_nodes_role" {
  project = var.project_id
  role    = "roles/container.nodeServiceAgent"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

resource "google_project_iam_member" "gke_nodes_compute" {
  project = var.project_id
  role    = "roles/compute.instanceAdmin.v1"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

resource "google_project_iam_member" "gke_nodes_monitoring" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

resource "google_project_iam_member" "gke_nodes_logging" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

resource "google_project_iam_member" "gke_nodes_sql_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

# ------------------------------------------------------
#                   Cloud SQL
# -----------------------------------------------------

resource "google_compute_global_address" "private_ip_range" {
  name         = "${var.prefix}-peering-range"
  purpose      = "VPC_PEERING"
  address_type = "INTERNAL"

  # Specify exact CIDR range
  address       = local.sql_cidr_address
  prefix_length = local.sql_cidr_prefix_length
  network       = google_compute_network.vpc_network.self_link
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.vpc_network.self_link
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_range.name]
}


# Cloud SQL Instance
resource "google_sql_database_instance" "mysql_instance" {
  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }
  name             = "${var.prefix}-sql-instance"
  project          = var.project_id
  region           = var.region
  database_version = var.db_version

  settings {
    tier = var.db_tier

    # Enable private IP if required
    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.vpc_network.self_link
    }

  }

  # Until I finsish
  deletion_protection = false
  depends_on          = [google_service_networking_connection.private_vpc_connection]
}

# Cloud SQL Database User and Password
resource "google_sql_user" "db_user" {
  name     = "${var.prefix}-user"
  instance = google_sql_database_instance.mysql_instance.name
  project  = var.project_id
  password = random_password.db_password.result
}

# Cloud SQL Database
resource "google_sql_database" "wordpress_db" {
  name     = "${var.prefix}-db"
  instance = google_sql_database_instance.mysql_instance.name
  project  = var.project_id
}

# Generate a random password for the database user
resource "random_password" "db_password" {
  length  = 16
  special = true
}


#----------------------------------------
# Kubernetes ----------------------------
#-----------------------------------------

# NFS Server Deployment
resource "kubernetes_deployment" "nfs_server" {
  metadata {
    name      = "${var.prefix}-nfs-server"
    namespace = kubernetes_namespace.wordpress.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "nfs-server"
      }
    }

    template {
      metadata {
        labels = {
          app = "nfs-server"
        }
      }

      spec {
        container {
          name  = "nfs-server"
          image = "k8s.gcr.io/volume-nfs:0.8"
          
          port {
            name          = "nfs"
            container_port = 2049
          }
          port {
            name          = "mountd"
            container_port = 20048
          }
          port {
            name          = "rpcbind"
            container_port = 111
          }

          security_context {
            privileged = true
          }

          volume_mount {
            name       = "nfs-pv-storage"
            mount_path = "/exports"
          }
        }

        volume {
          name = "nfs-pv-storage"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.nfs_server_storage.metadata[0].name
          }
        }
      }
    }
  }

  depends_on = [kubernetes_persistent_volume_claim.nfs_server_storage]
}

# NFS Server Service
resource "kubernetes_service" "nfs_server" {
  metadata {
    name      = "${var.prefix}-nfs-server"
    namespace = kubernetes_namespace.wordpress.metadata[0].name
  }

  spec {
    selector = {
      app = "nfs-server"
    }

    port {
      name = "nfs"
      port = 2049
    }
    port {
      name = "mountd"
      port = 20048
    }
    port {
      name = "rpcbind"
      port = 111
    }
  }
}

# Storage Class for NFS
resource "kubernetes_storage_class" "nfs" {
  metadata {
    name = "${var.prefix}-nfs"
  }

  storage_provisioner = "kubernetes.io/no-provisioner"
  reclaim_policy     = "Retain"
  depends_on = [kubernetes_deployment.nfs_server,kubernetes_service.nfs_server,kubernetes_persistent_volume_claim.nfs_server_storage]
}

# PVC for NFS Server Storage
resource "kubernetes_persistent_volume_claim" "nfs_server_storage" {
  metadata {
    name      = "${var.prefix}-nfs-server-storage"
    namespace = kubernetes_namespace.wordpress.metadata[0].name
  }

  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = var.pvc_storage_size
      }
    }
    storage_class_name = var.pvc_storage_class
  }

}
# Create Kubernetes Namespace
resource "kubernetes_namespace" "wordpress" {
  metadata {
    name = "wordpress-app"
  }
}

# Create Kubernetes Secret for Database Credentials
resource "kubernetes_secret" "db_credentials" {
  metadata {
    name      = "db-credentials"
    namespace = kubernetes_namespace.wordpress.metadata[0].name
  }

  data = {
    DB_NAME     = google_sql_database.wordpress_db.name
    DB_USER     = google_sql_user.db_user.name
    DB_PASSWORD = random_password.db_password.result
    DB_HOST     = google_sql_database_instance.mysql_instance.private_ip_address
  }

  type = "Opaque"
}


# PV for WordPress shared storage
resource "kubernetes_persistent_volume" "wordpress_shared" {
  metadata {
    name = "${var.prefix}-wordpress-shared"
  }

  spec {
    capacity = {
      storage = var.pvc_storage_size
    }
    access_modes = ["ReadWriteMany"]
    persistent_volume_source {
      nfs {
        server = kubernetes_service.nfs_server.spec[0].cluster_ip
        path   = "/exports"
      }
    }
    storage_class_name = kubernetes_storage_class.nfs.metadata[0].name
  }

}

# PVC for WordPress shared storage
resource "kubernetes_persistent_volume_claim" "wordpress_shared" {
  metadata {
    name      = "${var.prefix}-wordpress-shared"
    namespace = kubernetes_namespace.wordpress.metadata[0].name
  }

  spec {
    access_modes = ["ReadWriteMany"]
    resources {
      requests = {
        storage = var.pvc_storage_size
      }
    }
    storage_class_name = kubernetes_storage_class.nfs.metadata[0].name
  }

  depends_on = [kubernetes_persistent_volume.wordpress_shared]
}



resource "kubernetes_deployment" "wordpress" {
  metadata {
    name      = "wordpress"
    namespace = kubernetes_namespace.wordpress.metadata[0].name
    labels = {
      app = "wordpress"
    }
  }

  spec {
    replicas = var.hpa_min_replicas

    selector {
      match_labels = {
        app = "wordpress"
      }
    }

    template {
      metadata {
        labels = {
          app = "wordpress"
        }
      }

      spec {
        container {
          name  = "wordpress"
          image = "wordpress:latest"

          env {
            name = "WORDPRESS_DB_HOST"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.db_credentials.metadata[0].name
                key  = "DB_HOST"
              }
            }
          }

          env {
            name = "WORDPRESS_DB_USER"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.db_credentials.metadata[0].name
                key  = "DB_USER"
              }
            }
          }

          env {
            name = "WORDPRESS_DB_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.db_credentials.metadata[0].name
                key  = "DB_PASSWORD"
              }
            }
          }

          env {
            name = "WORDPRESS_DB_NAME"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.db_credentials.metadata[0].name
                key  = "DB_NAME"
              }
            }
          }
          env {
  name = "WORDPRESS_CONFIG_EXTRA"
  value = <<-EOT
    define('WP_HOME', 'http://' . $_SERVER['HTTP_HOST']);
    define('WP_SITEURL', 'http://' . $_SERVER['HTTP_HOST']);
  EOT
}

          port {
            container_port = 80
          }

          volume_mount {
            name       = "wordpress-persistent-storage"
            mount_path = "/var/www/html"
          }

          resources {
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "256Mi"
            }
          }

   readiness_probe {
  http_get {
    path = "/"
    port = 80
  }
  initial_delay_seconds = 30
  timeout_seconds      = 5
  period_seconds      = 10
}

liveness_probe {
  http_get {
    path = "/"
    port = 80
  }
  initial_delay_seconds = 60
  timeout_seconds      = 5
  period_seconds      = 15
}
        }

        volume {
          name = "wordpress-persistent-storage"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.wordpress_shared.metadata[0].name
          }
        }
      }
    }
  }
  depends_on = [ kubernetes_persistent_volume_claim.wordpress_shared ]
}
resource "kubernetes_service" "wordpress" {
  metadata {
    name      = "wordpress-service"
    namespace = kubernetes_namespace.wordpress.metadata[0].name
    labels = {
      app = "wordpress"
    }
  }

  spec {
    type = "NodePort"  # ClusterIP
    
    selector = {
      app = "wordpress"
    }

    port {
      port        = 80
      target_port = 80
      protocol    = "TCP"
      name        = "http"
    }
  }
}

# Horizontal Pod Autoscaler for WordPress
resource "kubernetes_horizontal_pod_autoscaler" "wordpress_hpa" {
  metadata {
    name      = "wordpress-hpa"
    namespace = kubernetes_namespace.wordpress.metadata[0].name
  }

  spec {
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment.wordpress.metadata[0].name
    }

    min_replicas = var.hpa_min_replicas
    max_replicas = var.hpa_max_replicas

    target_cpu_utilization_percentage = var.hpa_cpu_utilization
  }
}



# # TLS------------------------------
# Generate a private key
# Generate a private key
resource "tls_private_key" "selfsigned" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Create a self-signed TLS certificate
resource "tls_self_signed_cert" "selfsigned" {
  private_key_pem = tls_private_key.selfsigned.private_key_pem

  subject {
    common_name = "wordpress"  # Simplified common name
  }

  validity_period_hours = 8760 # 1 year

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

# Create Kubernetes TLS secret
resource "kubernetes_secret" "wordpress_tls" {
  metadata {
    name      = "wordpress-tls"
    namespace = kubernetes_namespace.wordpress.metadata[0].name
  }

  type = "kubernetes.io/tls"

  data = {
    "tls.crt" = tls_self_signed_cert.selfsigned.cert_pem
    "tls.key" = tls_private_key.selfsigned.private_key_pem
  }
}

# Create static IP for ingress
resource "google_compute_global_address" "wordpress_ip" {
  name    = "${var.prefix}-wordpress-ip"
  project = var.project_id
}

# Create ingress resource
resource "kubernetes_ingress_v1" "wordpress_ingress" {
  metadata {
    name      = "wordpress-ingress"
    namespace = kubernetes_namespace.wordpress.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.global-static-ip-name" = google_compute_global_address.wordpress_ip.name
      "kubernetes.io/ingress.class"                 = "gce"
      "kubernetes.io/ingress.allow-http"            = "true"
      "nginx.ingress.kubernetes.io/cors-allow-origin" = "*"
      "nginx.ingress.kubernetes.io/enable-cors" = "true"
      "ingress.gcp.kubernetes.io/v1beta1.BackendConfig" = jsonencode({
        default = {
          healthCheck = {
            checkIntervalSec = 15
            timeoutSec = 5
            healthyThreshold = 1
            unhealthyThreshold = 2
            type = "HTTP"
            requestPath = "/"
            port = 80
          }
        }
      })
    }
  }

  spec {
    tls {
      secret_name = kubernetes_secret.wordpress_tls.metadata[0].name
    }

    default_backend {
      service {
        name = kubernetes_service.wordpress.metadata[0].name
        port {
          number = 80
        }
      }
    }
  }

  depends_on = [
    kubernetes_secret.wordpress_tls,
    kubernetes_service.wordpress
  ]
}

# Create static IP for ingress
resource "google_compute_global_address" "wordpress_ip2" {
  name    = "${var.prefix}-ip2"
  project = var.project_id
}
# Outputs for Networking Stage

output "vpc_network_name" {
  description = "Name of the created VPC network."
  value       = google_compute_network.vpc_network.name
}

output "subnet_name" {
  description = "Name of the created subnet."
  value       = google_compute_subnetwork.private_subnet.name
}

output "vpc_network_self_link" {
  description = "Self link of the VPC network."
  value       = google_compute_network.vpc_network.self_link
}

output "subnet_self_link" {
  description = "Self link of the subnet."
  value       = google_compute_subnetwork.private_subnet.self_link
}

# Outputs for GKE Cluster (Stage B)

output "gke_cluster_name" {
  description = "Name of the GKE cluster."
  value       = google_container_cluster.primary.name
}

output "gke_cluster_endpoint" {
  description = "Endpoint of the GKE cluster."
  value       = google_container_cluster.primary.endpoint
}

output "gke_cluster_master_version" {
  description = "Master version of the GKE cluster."
  value       = google_container_cluster.primary.master_version
}

output "gke_cluster_location" {
  description = "Location of the GKE cluster."
  value       = google_container_cluster.primary.location
}

output "node_pool_name" {
  description = "Name of the GKE node pool."
  value       = google_container_node_pool.primary_nodes.name
}

# Outputs for Cloud SQL
output "db_instance_name" {
  description = "Name of the Cloud SQL instance."
  value       = google_sql_database_instance.mysql_instance.name
}

output "db_user" {
  description = "Database user for the application."
  value       = google_sql_user.db_user.name
}

output "db_password" {
  description = "Password for the database user (Sensitive)."
  value       = random_password.db_password.result
  sensitive   = true
}

output "db_connection_name" {
  description = "Connection name for Cloud SQL (used by GKE)."
  value       = google_sql_database_instance.mysql_instance.connection_name
}

# output "host" {
#   value = "https://${google_container_cluster.primary.endpoint}"
# }

# output "token" {
#   value = data.google_client_config.default.access_token
#   sensitive = true
# }

# output "cert" {
#   value = data.google_container_cluster.primary.master_auth[0].cluster_ca_certificate
# }

# output "db_dns" {
#   value=google_sql_database_instance.mysql_instance.dns_name
# }

output "db_ip" {
  value=google_sql_database_instance.mysql_instance.private_ip_address
}

# output "db_pubip" {
#   value=google_sql_database_instance.mysql_instance.public_ip_address
# }

# output "db_link" {
#   value = google_sql_database_instance.mysql_instance.self_link
# }

# Simple data source to get the ingress IP
# data "kubernetes_ingress_v1" "wordpress_ingress" {
#   metadata {
#     name      = kubernetes_ingress_v1.wordpress_ingress_http.metadata[0].name
#     namespace = kubernetes_namespace.wordpress.metadata[0].name
#   }
#   depends_on = [kubernetes_ingress_v1.wordpress_ingress_http]
# }

# Output the URL
# output "wordpress_url" {
#   description = "The URL of the WordPress application"
#   value       = "http://${data.kubernetes_ingress_v1.wordpress_ingress.status[0].load_balancer[0].ingress[0].ip}"
# }

# output "ingress_ip" {
#   value = kubernetes_ingress_v1.wordpress_ingress_http.status[0].load_balancer[0].ingress[0].ip
#   description = "The IP address of the Ingress for accessing the WordPress application"
# }


# output "ingress_hostname" {
#   value = kubernetes_ingress_v1.wordpress_ingress_http.status[0].load_balancer[0].ingress[0].ip
#   description = "The IP address of the Ingress for accessing the WordPress application"
# }

# terraform.tf

terraform {
  required_version = "~> 1.9.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.12.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.33.0 "
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6.3"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0.6"
    }
  }
  backend "gcs" {
    bucket = "gcp-wordpress-nov20204-nitzan-tf-state" # Replace with your GCS bucket name
    prefix = "terraform/state"
  }

}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "kubernetes" {
  host  = "https://${google_container_cluster.primary.endpoint}"
  token = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(
  data.google_container_cluster.primary.master_auth[0].cluster_ca_certificate,
  )
}



# variables.tf

# ==============================
# Project and Region Configuration
# ==============================

variable "project_id" {
  description = "GCP project ID where resources will be created."
  type        = string
}

variable "region" {
  description = "GCP region for resource deployment."
  type        = string
  default     = "me-west1"
}

# ==============================
# Resource Naming Prefix
# ==============================

variable "prefix" {
  description = "Prefix for naming resources."
  type        = string
  default     = "wordpress"
}

# ==============================
# VPC and Subnet Configuration
# ==============================

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
  description = "CIDR block for the sql within the VPC.(dont add subnetmask)"
  type        = string
  default     = "10.0.3.0/24"
}

# ==============================
# Tags for Resource Identification
# ==============================

variable "tags" {
  description = "Labels/tags to apply to resources."
  type        = map(string)
  default = {
    "managed-by"  = "terraform"
    "team"        = "devops"
    "environment" = "test"
  }
}

# ==============================
# (Optional) Additional Variables for Future Stages
# ==============================

# Node Pool Configuration
variable "machine_type" {
  description = "Machine type for GKE nodes."
  type        = string
  default     = "e2-medium"
}

variable "disk_size_gb" {
  description = "Disk size for GKE nodes (GB)."
  type        = number
  default     = 15
}

variable "min_node_count" {
  description = "Minimum number of nodes in the node pool per zone."
  type        = number
  default     = 1
}

variable "max_node_count" {
  description = "Maximum number of nodes in the node pool per zone."
  type        = number
  default     = 3
}

# Storage Configuration
variable "storage_class" {
  description = "Storage class for Persistent Volumes."
  type        = string
  default     = "pd-balanced"
}

variable "storage_size" {
  description = "Storage size for Persistent Volume (Gi)."
  type        = string
  default     = "20Gi"
}

# Kubernetes Deployment Configuration
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

# ---------------------
# DB
#----------------------------

# Database Configuration
variable "db_tier" {
  description = "The tier (machine type) for the Cloud SQL instance."
  type        = string
  default     = "db-f1-micro"
}

# Database version
variable "db_version" {
  description = "The database version for the Cloud SQL instance."
  type        = string
  default     = "MYSQL_8_0"
}

# ==============================
# PVC Storage Configuration
# ==============================
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