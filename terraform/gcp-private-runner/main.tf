provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# Enable APIs we need

resource "google_project_service" "compute" {
  project = var.project_id
  service = "compute.googleapis.com"
}

resource "google_project_service" "secretmanager" {
  project = var.project_id
  service = "secretmanager.googleapis.com"
}

# Service Account for the VM
resource "google_service_account" "runner_sa" {
  account_id   = "gh-runner-sa"
  display_name = "GitHub Runner SA"
}

# Allow VM to read Secret Manager, use Compute
resource "google_project_iam_binding" "sm_access" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  members = ["serviceAccount:${google_service_account.runner_sa.email}"]
}

resource "google_project_iam_binding" "compute_user" {
  project = var.project_id
  role    = "roles/compute.instanceAdmin.v1"
  members = ["serviceAccount:${google_service_account.runner_sa.email}"]
}

# Optional: minimalist firewall to allow SSH from IAP for debug (comment out if not needed)
resource "google_compute_firewall" "allow_iap_ssh" {
  name    = "allow-iap-ssh"
  network = var.network

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"] # IAP TCP forwarding
  direction     = "INGRESS"
}

# Random suffix for unique VM names
resource "random_id" "suffix" { byte_length = 3 }

# Instance with startup script that registers ephemeral runner
resource "google_compute_instance" "ephemeral_runner" {
  name         = "gh-runner-${random_id.suffix.hex}"
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "projects/debian-cloud/global/images/family/debian-12"
      size  = 20
    }
  }

  network_interface {
    network    = var.network
    subnetwork = var.subnetwork
    # ephemeral public IP (remove if you only use IAP/Private NAT)
    access_config {}
  }

  service_account {
    email  = google_service_account.runner_sa.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  metadata = {
    # Pass values to startup script as metadata
    repo_owner      = var.repo_owner
    repo_name       = var.repo_name
    runner_labels   = join(",", var.runner_labels)
    pat_secret_name = var.github_pat_secret
  }

  metadata_startup_script = file("${path.module}/startup.sh")

  tags = ["gh-runner"]
}

# Output the label we expect, so workflow can target it
output "runner_labels" {
  value = var.runner_labels
}
