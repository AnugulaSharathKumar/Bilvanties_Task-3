#!/bin/bash
set -euo pipefail

# Usage: terraform_deploy.sh [RUNNER_TOKEN]
# If RUNNER_TOKEN is provided as the first argument it will be used,
# otherwise the script will use the TF_VAR_runner_token environment variable.

if [ "$#" -gt 0 ] && [ -n "$1" ]; then
  export TF_VAR_runner_token="$1"
fi

if [ -z "${TF_VAR_runner_token:-}" ]; then
  echo "Error: runner token not supplied. Pass as arg or set TF_VAR_runner_token." >&2
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "Running terraform init..."
terraform init -input=false

echo "Running terraform plan..."
terraform plan -input=false

echo "Applying terraform changes..."
terraform apply -auto-approve -input=false

echo "Terraform apply complete."
