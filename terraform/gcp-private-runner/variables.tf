variable "project_id"        { type = string }
variable "region"            { type = string  default = "asia-south1" }
variable "zone"              { type = string  default = "asia-south1-a" }
variable "machine_type"      { type = string  default = "e2-standard-2" }
variable "tf_state_bucket"   { type = string }

# GitHub details
variable "repo_owner"        { type = string }   # e.g. "AnugulaSharathKumar"
variable "repo_name"         { type = string }   # e.g. "Bilvanties_Task-3"
variable "runner_labels"     { type = list(string) default = ["gcp-gce", "linux"] }

# Secret Manager: name of secret containing your GitHub PAT
variable "github_pat_secret" { type = string }   # e.g. "github-pat"

# Networking (optional). If you already have a VPC, wire it in here.
variable "network"           { type = string  default = "default" }
variable "subnetwork"        { type = string  default = null }

# Instance and module options
variable "instance_name"     { type = string  default = "private-runner-instance" }
variable "enable_project_services" { type = bool default = false }
