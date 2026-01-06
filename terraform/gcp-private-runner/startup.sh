
#!/usr/bin/env bash
set -euxo pipefail

# Read metadata
REPO_OWNER="$(curl -s -H 'Metadata-Flavor: Google' http://metadata.google.internal/computeMetadata/v1/instance/attributes/repo_owner)"
REPO_NAME="$(curl -s -H 'Metadata-Flavor: Google' http://metadata.google.internal/computeMetadata/v1/instance/attributes/repo_name)"
RUNNER_LABELS="$(curl -s -H 'Metadata-Flavor: Google' http://metadata.google.internal/computeMetadata/v1/instance/attributes/runner_labels)"
PAT_SECRET_NAME="$(curl -s -H 'Metadata-Flavor: Google' http://metadata.google.internal/computeMetadata/v1/instance/attributes/pat_secret_name)"

# Basic deps
apt-get update -y
apt-get install -y curl jq tar ca-certificates git
curl -fsSL https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh | bash || true
systemctl enable google-cloud-ops-agent || true

# Install gcloud CLI (for Secret Manager)
if ! command -v gcloud >/dev/null 2>&1; then
  apt-get install -y apt-transport-https gnupg lsb-release
  echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" \
    | tee /etc/apt/sources.list.d/google-cloud-sdk.list
  curl https://packages.cloud.google.com/apt/doc/apt-key.gpg \
    | tee /usr/share/keyrings/cloud.google.gpg >/dev/null
  apt-get update -y && apt-get install -y google-cloud-sdk
fi

# Get GitHub PAT from Secret Manager
GITHUB_PAT="$(gcloud secrets versions access latest --secret="${PAT_SECRET_NAME}")"

# Fetch GitHub registration token (valid ~60 minutes)
REG_TOKEN="$(curl -s -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: token ${GITHUB_PAT}" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/actions/runners/registration-token" \
  | jq -r '.token')"

# Download actions runner
mkdir -p /opt/actions-runner && cd /opt/actions-runner
RUNNER_VERSION_URL="https://api.github.com/repos/actions/runner/releases/latest"
LATEST_URL="$(curl -s ${RUNNER_VERSION_URL} | jq -r '.assets[] | select(.name|test("linux-x64")).browser_download_url')"
curl -L -o actions-runner-linux-x64.tar.gz "${LATEST_URL}"
tar xzf actions-runner-linux-x64.tar.gz

# Configure as ephemeral (one job only) and start
./config.sh \
  --url "https://github.com/${REPO_OWNER}/${REPO_NAME}" \
  --token "${REG_TOKEN}" \
  --labels "${RUNNER_LABELS}" \
  --name "gcp-${HOSTNAME}" \
  --ephemeral \
  --unattended

# Install and start as service
./svc.sh install
./svc.sh start

# Optional: after the job completes, runner exits (ephemeral).
# Cleanup is handled by Terraform destroy in the workflow.
``
