
output "instance_name" {
  description = "Runner instance name"
  value       = google_compute_instance.runner.name
}

output "zone" {
  description = "Zone where the runner instance is created"
  value       = google_compute_instance.runner.zone
}

output "github_url" {
  description = "GitHub repository URL used by the runner"
  value       = "https://github.com/${var.github_repo}"
}
