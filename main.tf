module "gcp_infrastructure" {
  source = "./modules/gcp"
  # General Configuration
  project_id = var.project_id
  region     = var.region

  # Resource Naming Prefix
  prefix = var.prefix

  # Tags
  tags = var.tags

  # VPC and Subnet Configuration
  vpc_cidr            = var.vpc_cidr
  subnet_cidr_cluster = var.subnet_cidr_cluster
  cidr_range_sql      = var.cidr_range_sql

  # GKE Node Pool Configuration
  machine_type   = var.machine_type
  disk_type      = var.disk_type
  disk_size_gb   = var.disk_size_gb
  min_node_count = var.min_node_count
  max_node_count = var.max_node_count

  # Database Configuration
  db_tier    = var.db_tier
  db_version = var.db_version
}

# K8s Module
module "k8s_deployment" {
  source = "./modules/k8s"

  # General Configuration
  project_id = var.project_id
  region     = var.region
  prefix     = var.prefix
  tags       = var.tags

  # Namespace Configuration
  namespace = var.namespace

  # WordPress Deployment Configuration
  wordpress_image = var.wordpress_image
  wordpress_tag   = var.wordpress_tag
  replica_count   = var.replica_count

  # Horizontal Pod Autoscaler Configuration
  hpa_min_replicas    = var.hpa_min_replicas
  hpa_max_replicas    = var.hpa_max_replicas
  hpa_cpu_utilization = var.hpa_cpu_utilization

  # PVC Storage Configuration
  pvc_storage_class = var.pvc_storage_class
  pvc_storage_size  = var.pvc_storage_size

  # Database Configuration (from GCP module outputs)
  wordpress_db_instance_name   = module.gcp_infrastructure.db_instance_name
  wordpress_db_user            = module.gcp_infrastructure.db_user
  wordpress_db_password        = module.gcp_infrastructure.db_password
  wordpress_db_connection_name = module.gcp_infrastructure.db_connection_name
  wordpress_db_ip              = module.gcp_infrastructure.db_ip
  wordpress_db_name            = module.gcp_infrastructure.wordpress_db_name

  # Global IP Configuration (from GCP module outputs)
  wordpress_ip_address      = module.gcp_infrastructure.wordpress_ip_address
  wordpress_ip_address_name = module.gcp_infrastructure.wordpress_ip_address_name
}