resource "google_compute_network" "private_vpc" {
  name                    = "private-runner-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "private_subnet" {
  name          = "private-runner-subnet"
  region        = var.region
  network       = google_compute_network.private_vpc.id
  ip_cidr_range = "10.10.0.0/24"
}
