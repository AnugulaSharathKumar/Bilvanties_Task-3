
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = local.project_id
}

locals {
  # Use variables from module inputs
  project_id  = var.project_id
  org_or_user = var.repo_owner
  repo_name   = var.repo_name

  # Service Account the workflow will impersonate
  sa_id       = "gh-actions"

  # Names for pool & provider
  pool_id     = "github-actions"
  provider_id = "github-oidc"

  # Optional roles for the SA (add/remove as needed)
  sa_roles = [
    "roles/storage.admin",
    "roles/compute.admin",
  ]
} 

# Enable IAM API (if not already)
resource "google_project_service" "iam" {
  project = local.project_id
  service = "iam.googleapis.com"
}

# Create service account to be impersonated by GitHub Actions
resource "google_service_account" "gh_sa" {
  account_id   = local.sa_id
  display_name = "GitHub Actions OIDC SA"
}

# Assign roles to the service account (so the workload can do things)
resource "google_project_iam_member" "sa_iam_roles" {
  for_each = toset(local.sa_roles)
  project  = local.project_id
  role     = each.value
  member   = "serviceAccount:${google_service_account.gh_sa.email}"
}

# Create Workload Identity Pool
resource "google_iam_workload_identity_pool" "pool" {
  project                         = local.project_id
  workload_identity_pool_id       = local.pool_id
  display_name                    = "GitHub Actions Pool"
  description                     = "Keyless auth for GitHub Actions → GCP"
}

# Create OIDC Provider for GitHub Actions (issuer = token.actions.githubusercontent.com)
resource "google_iam_workload_identity_pool_provider" "provider" {
  project                             = local.project_id
  workload_identity_pool_id           = google_iam_workload_identity_pool.pool.workload_identity_pool_id
  workload_identity_pool_provider_id  = local.provider_id
  display_name                        = "GitHub OIDC Provider"

  # Map GitHub OIDC claims to attributes you can use in IAM bindings
  attribute_mapping = {
    "google.subject"             = "assertion.sub"
    "attribute.actor"            = "assertion.actor"
    "attribute.repository"       = "assertion.repository"
    "attribute.repository_owner" = "assertion.repository_owner"
  }

  # Restrict to a specific repo (tightest scope):
  # Only tokens from repo owner/repo_name are trusted.
  attribute_condition = "assertion.repository == '${local.org_or_user}/${local.repo_name}'"

  oidc {
    issuer_uri        = "https://token.actions.githubusercontent.com"
    # No fixed audience required for google-github-actions/auth
    allowed_audiences = []
  }
}

# Allow identities from this provider/pool to impersonate the SA
# principalSet pattern binds based on attribute mappings above.
resource "google_service_account_iam_member" "wif_binding" {
  service_account_id = google_service_account.gh_sa.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/projects/${data.google_project.project.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.pool.workload_identity_pool_id}/attribute.repository/${local.org_or_user}/${local.repo_name}"
}

data "google_project" "project" {
  project_id = local.project_id
}

# Service account used by the ephemeral runner instance (can access Secret Manager)
resource "google_service_account" "runner_sa" {
  account_id   = "${var.instance_name}-sa"
  display_name = "GitHub Runner service account"
}

# Grant the runner SA permission to access secrets in Secret Manager.
# This is a broad permission (project-level). If you'd like a more restricted binding
# we can switch to `google_secret_manager_secret_iam_member` bound to a single secret.
resource "google_project_iam_member" "runner_sa_secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.runner_sa.email}"
}

# Compute instance for the ephemeral self-hosted runner
resource "google_compute_instance" "runner" {
  name         = var.instance_name
  zone         = var.zone
  machine_type = var.machine_type

  boot_disk {
    initialize_params {
      image = "projects/ubuntu-os-cloud/global/images/family/ubuntu-2204-lts"
    }
  }

  network_interface {
    network    = var.network
    subnetwork = var.subnetwork
    access_config {}
  }

  metadata = {
    repo_owner      = var.repo_owner
    repo_name       = var.repo_name
    runner_labels   = join(",", var.runner_labels)
    pat_secret_name = var.github_pat_secret
  }

  metadata_startup_script = file("${path.module}/startup.sh")

  service_account {
    email  = google_service_account.runner_sa.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  tags = ["github-runner"]
}
