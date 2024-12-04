#-------------------data----------------
# data.tf
data "google_client_config" "default" {}

# Retrieve cluster credentials
data "google_container_cluster" "primary" {
  name     = module.gcp_infrastructure.gke_cluster_name
  location = var.region
  project  = var.project_id
}