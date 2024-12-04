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
  host  = "https://${data.google_container_cluster.primary.endpoint}"
  token = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(
    data.google_container_cluster.primary.master_auth[0].cluster_ca_certificate,
  )
}