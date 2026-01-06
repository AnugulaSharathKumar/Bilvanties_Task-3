
resource "google_compute_instance" "runner" {
  name         = var.instance_name
  zone         = var.zone
  machine_type = var.machine_type

  # Ensure APIs (if toggled) before instance create
  depends_on = [
    google_project_service.compute_api,
    google_project_service.oslogin_api
  ]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 20
      type  = "pd-balanced"
    }
  }

  network_interface {
    subnetwork  = var.subnetwork
    access_config {} # ephemeral public IP; remove if NAT/VPN
  }

  metadata_startup_script = file(var.startup_script)

  metadata = {
    github_url    = "https://github.com/${var.github_repo}"
    runner_token  = var.runner_token
    runner_labels = "self-hosted,linux,private"
  }

  scheduling {
    automatic_restart   = false
    on_host_maintenance = "MIGRATE"
    # preemptible = true  # uncomment if you want ephemeral, cheaper runners
  }

  tags = ["runner"]
}
