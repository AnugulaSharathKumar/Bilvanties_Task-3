variable "project_id" {
  description = "GCP Project ID"
}

variable "region" {
  description = "GCP Region"
}

variable "zone" {
  description = "GCP Zone"
}

variable "github_owner" {
  description = "GitHub username or org"
}

variable "github_repo" {
  description = "GitHub repository name"
}

variable "runner_token" {
  description = "GitHub self-hosted runner registration token"
  sensitive   = true
}
