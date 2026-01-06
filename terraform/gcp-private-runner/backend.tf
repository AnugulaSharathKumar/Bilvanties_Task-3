terraform {
  backend "gcs" {
    bucket = var.tf_state_bucket
    prefix = "github-runner/ephemeral"
  }
  required_version = ">= 1.5.0"
}
