
#!/usr/bin/env bash
set -euxo pipefail

# Simple helper to read instance metadata
get_meta() {
  curl -s -H 'Metadata-Flavor: Google' "http://metadata.google.internal/computeMetadata/v1/instance/attributes/$1" || true
}

REPO_OWNER="$(get_meta repo_owner)"
REPO_NAME="$(get_meta repo_name)"
RUNNER_LABELS="$(get_meta runner_labels)"
PAT_SECRET_NAME="$(get_meta pat_secret_name)"
RUNNER_TOKEN="$(get_meta runner_token)"

# Install basic deps
apt-get update -y
apt-get install -y curl jq tar ca-certificates git

# Install gcloud CLI (for Secret Manager access) if needed
if ! command -v gcloud >/dev/null 2>&1; then
  apt-get install -y apt-transport-https gnupg lsb-release
  echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" \
    | tee /etc/apt/sources.list.d/google-cloud-sdk.list
  curl https://packages.cloud.google.com/apt/doc/apt-key.gpg \
    | tee /usr/share/keyrings/cloud.google.gpg >/dev/null
  apt-get update -y && apt-get install -y google-cloud-sdk
fi

# Determine registration token: prefer runner_token provided via metadata
if [ -n "${RUNNER_TOKEN}" ] && [ "${RUNNER_TOKEN}" != "null" ]; then
  REG_TOKEN="${RUNNER_TOKEN}"
else
  if [ -n "${PAT_SECRET_NAME}" ] && [ "${PAT_SECRET_NAME}" != "null" ]; then
    # Fetch GitHub PAT from Secret Manager
    GITHUB_PAT="$(gcloud secrets versions access latest --secret="${PAT_SECRET_NAME}")"

    # Request a repo-level registration token
    REG_TOKEN="$(curl -s -X POST \
      -H "Accept: application/vnd.github+json" \
      -H "Authorization: token ${GITHUB_PAT}" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      "https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/actions/runners/registration-token" \
      | jq -r '.token')"
  else
    echo "No runner_token metadata and no pat_secret_name; cannot obtain registration token" >&2
    exit 1
  fi
fi

# Download and extract latest GitHub Actions runner
mkdir -p /opt/actions-runner && cd /opt/actions-runner
RUNNER_VERSION_URL="https://api.github.com/repos/actions/runner/releases/latest"
LATEST_URL="$(curl -s ${RUNNER_VERSION_URL} | jq -r '.assets[] | select(.name|test("linux-x64")).browser_download_url')"
curl -L -o actions-runner-linux-x64.tar.gz "${LATEST_URL}"
tar xzf actions-runner-linux-x64.tar.gz

# Configure the runner as ephemeral
./config.sh \
  --url "https://github.com/${REPO_OWNER}/${REPO_NAME}" \
  --token "${REG_TOKEN}" \
  --labels "${RUNNER_LABELS}" \
  --name "gcp-${HOSTNAME}" \
  --ephemeral \
  --unattended

# Run the runner in the foreground. It will exit when its single job completes (ephemeral runner).
./run.sh

# When ./run.sh exits (job completed or failed), shutdown the VM to save costs.
echo "Runner exited; shutting down VM"
shutdown -h now
