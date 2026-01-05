resource "google_compute_network" "runner_net" {
  name                    = "runner-net"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "runner_subnet" {
  name          = "runner-subnet"
  region        = var.region
  network       = google_compute_network.runner_net.id
  ip_cidr_range = "10.10.0.0/24"
}

resource "google_compute_firewall" "allow_ssh" {
  name    = "runner-allow-ssh"
  network = google_compute_network.runner_net.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = var.ssh_source_ranges
}

resource "google_compute_instance" "runner" {
  name         = var.instance_name
  zone         = var.zone
  machine_type = var.machine_type

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 10
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.runner_subnet.name
    access_config {} # public IP for simplicity (remove if using NAT/VPN)
  }

  metadata_startup_script = file("${path.module}/startup.sh")

  metadata = {
    github_url   = "https://github.com/${var.github_repo}"
    runner_token = "will-be-overwritten-by-pipeline"
  }

  scheduling {
    automatic_restart   = false
    on_host_maintenance = "TERMINATE"
  }

  tags = ["runner"]
}
