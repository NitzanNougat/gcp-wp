# ./modules/monitoring/main.tf

resource "google_monitoring_notification_channel" "email" {
  display_name = "${var.prefix}-alert-email-channel"
  project      = var.project_id
  type         = "email"

  labels = {
    email_address = var.alert_email_address
  }
}

# Alert Policy for CPU Usage
resource "google_monitoring_alert_policy" "cpu_usage" {
  display_name = "${var.prefix}-high-cpu-usage-policy"
  project      = var.project_id
  combiner     = "OR"

  conditions {
    display_name = "CPU usage above threshold"

    condition_threshold {
      filter = "resource.type = \"k8s_container\" AND resource.labels.namespace_name = \"${var.k8s_namespace}\" AND metric.type = \"kubernetes.io/container/cpu/request_utilization\""
      
      duration        = "60s"
      comparison     = "COMPARISON_GT"
      threshold_value = var.hpa_cpu_alert_threshold

      trigger {
        count = 1
      }

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.id]

  alert_strategy {
    auto_close = "1800s"
  }
}

