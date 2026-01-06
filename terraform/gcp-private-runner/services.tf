# Enable required Google Cloud APIs (disabled by default)
# NOTE: Enabling services via Terraform requires the caller to have
# roles/serviceusage.serviceUsageAdmin on the target project.
resource "google_project_service" "compute_api" {
  count = var.enable_project_services ? 1 : 0
  project = var.project_id
  service = "compute.googleapis.com"
  disable_on_destroy = false
}

# Optional: enable IAM API as well
resource "google_project_service" "iam_api" {
  count = var.enable_project_services ? 1 : 0
  project = var.project_id
  service = "iam.googleapis.com"
  disable_on_destroy = false
}
