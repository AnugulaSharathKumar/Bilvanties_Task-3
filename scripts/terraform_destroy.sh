#!/bin/bash
set -euo pipefail

# Usage: terraform_destroy.sh [RUNNER_TOKEN]
# Destroys the infrastructure created by the root terraform module.

if [ "$#" -gt 0 ] && [ -n "$1" ]; then
  export TF_VAR_runner_token="$1"
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "Running terraform init..."
terraform init -input=false

echo "Running terraform destroy..."
terraform destroy -auto-approve -input=false

echo "Terraform destroy complete."
