module "github_runner" {
  source = "./terraform/gcp-private-runner"

  project_id   = var.project_id
  region       = var.region
  zone         = var.zone
  github_owner = var.github_owner
  github_repo  = var.github_repo
  runner_token = var.runner_token
}
