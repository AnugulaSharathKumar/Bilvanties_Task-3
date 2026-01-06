output "runner_private_ip" {
  value = google_compute_instance.github_runner.network_interface[0].network_ip
}
