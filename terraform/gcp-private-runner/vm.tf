resource "google_compute_instance" "github_runner" {
  name         = "github-self-hosted-runner"
  machine_type = "e2-medium"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "ubuntu-2204-lts"
      size  = 20
    }
  }

  network_interface {
    network    = google_compute_network.private_vpc.id
    subnetwork = google_compute_subnetwork.private_subnet.id
  }

  metadata = {
    startup-script = templatefile("${path.module}/../scripts/startup.sh", {
      github_owner = var.github_owner
      github_repo  = var.github_repo
      runner_token = var.runner_token
    })
  }

  tags = ["github-runner"]

  service_account {
    scopes = ["cloud-platform"]
  }
}
