

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
    name = var.namespace
  }
}

# Create Kubernetes Secret for Database Credentials
resource "kubernetes_secret" "db_credentials" {
  metadata {
    name      = "db-credentials"
    namespace = kubernetes_namespace.wordpress.metadata[0].name
  }

  data = {
    DB_NAME     = var.wordpress_db_name
    DB_USER     = var.wordpress_db_user
    DB_PASSWORD = var.wordpress_db_password
    DB_HOST     = var.wordpress_db_ip
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
          env {
            name = "APACHE_SERVER_NAME"
            value = "wordpress"
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


# Create ingress resource
resource "kubernetes_ingress_v1" "wordpress_ingress" {
  metadata {
    name      = "wordpress-ingress"
    namespace = kubernetes_namespace.wordpress.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.global-static-ip-name" = var.wordpress_ip_address_name
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
#--------------------------------------------alerts part

