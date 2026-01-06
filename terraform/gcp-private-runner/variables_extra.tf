variable "enable_project_services" {
  type        = bool
  default     = false
  description = "If true, Terraform will enable required GCP services (requires roles/serviceusage.serviceUsageAdmin)."
}
