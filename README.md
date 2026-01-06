# Bilvanties_Task-3

Minimal repository for the GCP self-hosted GitHub runner Terraform module and startup script.

Usage
 - Run the Terraform automation scripts from this repository root.

Local deploy (one-time):
```bash
export TF_VAR_runner_token="<RUNNER_TOKEN>"
./scripts/terraform_deploy.sh
```

Local destroy:
```bash
./scripts/terraform_destroy.sh
```

CI: A GitHub Actions workflow is provided at `.github/workflows/deploy.yml` which reads the
`RUNNER_TOKEN` secret (or accepts a `runner_token` workflow input) and `GCP_CREDENTIALS` service account JSON.

Secrets required for the workflow:
- `GCP_CREDENTIALS` — service account JSON with permissions to create compute and network resources.
- `RUNNER_TOKEN` — GitHub self-hosted runner registration token (optional if supplied at workflow dispatch).
#
#### Bilvanties_Task-3


terraform init -no-color
terraform plan -no-color

export TF_VAR_runner_token="REPLACE_WITH_TOKEN"
terraform apply