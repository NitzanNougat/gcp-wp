
# =========================================
# GCP Main
# =========================================

# ./modules/gcp/main.tf

# Locals Block
locals {
  required_services = [
    "compute.googleapis.com",
    "container.googleapis.com",
    "sqladmin.googleapis.com",
    "iam.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "servicenetworking.googleapis.com",
    "file.googleapis.com",
    "cloudtrace.googleapis.com",           
    "clouderrorreporting.googleapis.com",   
    "cloudprofiler.googleapis.com",         
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
  timeouts {
    create = "20m"
    update = "20m"
    delete = "20m"
  }
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
    disk_type    = var.disk_type
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
    create = "40m"
    update = "40m"
    delete = "40m"
  }
  name             = "${var.prefix}-sql-instance"
  project          = var.project_id
  region           = var.region
  database_version = var.db_version

  settings {
    tier = var.db_tier

    backup_configuration {
      enabled                        = true
      start_time                     = "03:00"
      location                       = var.region
    }

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

# Create static IP for ingress
resource "google_compute_global_address" "wordpress_ip" {
  name    = "${var.prefix}-wordpress-ip"
  project = var.project_id
}