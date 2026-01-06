
variable "project_id" {
  type        = string
  description = "GCP project ID"
}

variable "region" {
  type        = string
  description = "GCP region (e.g., us-central1)"
}

variable "zone" {
  type        = string
  description = "GCP zone (e.g., us-central1-a)"
}

variable "instance_name" {
  type        = string
  description = "Compute instance name for the self-hosted runner"
}

variable "machine_type" {
  type        = string
  default     = "e2-standard-2"
  description = "Machine type for the runner VM"
}

variable "subnetwork" {
  type        = string
  description = "Existing subnetwork name (recommended to reuse an existing VPC/subnet)"
}

variable "startup_script" {
  type        = string
  description = "Path to startup.sh that configures the GitHub Actions runner"
}

variable "github_repo" {
  type        = string
  description = "GitHub repo in OWNER/REPO format (e.g., AnugulaSharathKumar/Bilvanties_Task-3)"
}

variable "runner_token" {
  type        = string
  sensitive   = true
  description = "Short-lived GitHub Actions runner registration token (passed from workflow)"
}

variable "enable_project_services" {
  type        = bool
  default     = false
  description = "If true, Terraform will enable required GCP services (requires roles/serviceusage.serviceUsageAdmin)."
}
