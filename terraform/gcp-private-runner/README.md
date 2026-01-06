# gcp-private-runner module

Pre-requisites:
- The Compute Engine API (`compute.googleapis.com`) and Service Usage API must be enabled in the target project if `enable_project_services` is `false` (the module will **not** try to enable them). 
- If you want Terraform to enable required APIs, set `enable_project_services = true` and ensure the credentials used to apply have the `roles/serviceusage.serviceUsageAdmin` role on the target project.

Usage examples:
- To let Terraform enable APIs (requires service usage admin):

```hcl
module "runner" {
  source = "./terraform/gcp-private-runner"
  enable_project_services = true
}
```

- To enable APIs manually and proceed without Terraform managing them:

```bash
gcloud services enable compute.googleapis.com --project=PROJECT_ID
```

Notes:
- If you prefer that Terraform manages IAM bindings to grant the Service Usage Admin role, I can add that, but it requires an account with sufficient privileges to modify IAM policy.
- I also fixed the `metadata.github_url` to use the `var.github_repo` value directly (avoid double `https://github.com/` prefix).

How to run jobs on this ephemeral runner
---------------------------------------
1) Add repository secrets:
   - `GCP_SERVICE_ACCOUNT_KEY` – JSON key for a GCP service account with permission to start/stop the VM (e.g. `roles/compute.instanceAdmin.v1` or a more limited role that includes `compute.instances.start`, `compute.instances.stop`, and `compute.instances.addMetadata`).
   - `GCP_PROJECT_ID` – the target GCP project id used by the workflow.
   - (Optional) Store a GitHub Personal Access Token in Secret Manager and pass its secret name via the module input `github_pat_secret` if you want the VM to fetch a PAT directly; otherwise the workflow will request a short-lived registration token and write it to the instance metadata.

2) Example workflow: `.github/workflows/start-runner-and-execute.yml` (added to this repo) starts the instance with a fresh registration token and then runs the job on `runs-on: [self-hosted, linux, private]`. The instance's `startup.sh` registers an ephemeral runner that automatically unregisters after doing one job and then shuts the VM down.

3) Job flow details:
   - `start-runner` job (hosted runner) requests a registration token from GitHub Actions API and injects it into the instance metadata.
   - The instance retrieves `runner_token` and `github_url` metadata at boot (your `startup.sh` already does this), registers as an ephemeral runner and runs `./run.sh`.

> Note: `startup.sh` now installs Actions Runner v2.330.0 and validates the tarball SHA256. It now *requires* `runner_token` to be provided via instance metadata or `var.runner_token`—the script exits if no token is supplied. Prefer passing the registration token via metadata/CI to avoid committing secrets to the repository.
   - After the runner finishes the single job, the startup script calls `shutdown -h now` to stop the VM.

4) If you want Terraform to manage enabling the Compute API automatically, set `enable_project_services = true` in your module call and run `terraform apply` with a principal that has `roles/serviceusage.serviceUsageAdmin`.

If you'd like, I can:
- Add a more robust waiter that polls the repo's runners API until the runner is active before proceeding, or
- Add a separate lightweight "start-only" workflow that just starts the VM (useful if you don't want to embed start/execute in a single workflow).
