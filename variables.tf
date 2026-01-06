variable "project_id" {
  description = "GCP Project ID"
  default     = "my-learning-terraform-482905"
}

variable "region" {
  description = "GCP Region"
  default     = "asia-south1"
}

variable "zone" {
  description = "GCP Zone"
  default     = "asia-south1-a"
}

variable "github_owner" {
  description = "GitHub username or org"
  default     = "AnugulaSharathKumar"
}

variable "github_repo" {
  description = "GitHub repository name"
  default     = "Bilvanties_Task-3"
}

variable "runner_token" {
  description = "GitHub self-hosted runner registration token"
  type        = string
  sensitive   = true
  default     = ""
}
