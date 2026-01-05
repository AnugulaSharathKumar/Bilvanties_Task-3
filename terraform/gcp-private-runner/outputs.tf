output "instance_name" {
     value = google_compute_instance.runner.name
      }
output "zone"          {
     value = google_compute_instance.runner.zone
      }
output "github_url"    {
     value = "https://github.com/${var.github_repo}"
      }
