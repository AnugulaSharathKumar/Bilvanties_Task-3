variable "project_id" {
  type        = string
  default     = "my-gcp-project"
  description = "GCP Project ID where resources will be created"
}
variable "region" {
  type        = string
  default     = "us-central1"
  description = "GCP Region where resources will be created"
}
variable "zone" {
  type        = string
  default     = "us-central1-a"
  description = "GCP Zone where resources will be created"
}
variable "machine_type" {
  type        = string
  default     = "e2-micro"
  description = "Machine type for the private runner instance"
}
variable "instance_name" {
  type        = string
  default     = "private-runner-instance"
  description = "Name of the private runner instance"
}
variable "github_repo" {
  type        = string
  default     = "https://github.com/AnugulaSharathKumar/Bilvanties_Task-3.git"
  description = "GitHub repository URL for the private runner"
}
variable "ssh_source_ranges" {
  type        = list(string)
  default     = ["0.0.0.0/0"]
    description = "List of CIDR blocks allowed to access the instance via SSH"  
}