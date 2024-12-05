# ./modules/monitoring/main.tf

resource "google_monitoring_notification_channel" "email" {
  display_name = "${var.prefix}-alert-email-channel"
  project      = var.project_id
  type         = "email"

  labels = {
    email_address = var.alert_email_address
  }
}