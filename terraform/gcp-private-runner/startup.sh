#!/bin/bash
set -euo pipefail

########################################
# Configuration
########################################
RUNNER_VERSION="2.330.0"
RUNNER_DIR="/opt/actions-runner"
LABELS="private,ubuntu,linux,gcp"
RUNNER_TOKEN="AV2UD2EWN22VL3XBHWJ3PZ3JLTOTM"

TARBALL="actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz"
TARBALL_SHA256="af5c33fa94f3cc33b8e97937939136a6b04197e6dadfcfb3b6e33ae1bf41e79a"

META_URL="http://metadata.google.internal/computeMetadata/v1/instance/attributes"
META_HEADER="Metadata-Flavor: Google"

########################################
# Install dependencies
########################################
apt-get update -y
apt-get install -y curl tar jq git perl

########################################
# Setup runner directory
########################################
mkdir -p "${RUNNER_DIR}"
cd "${RUNNER_DIR}"

########################################
# Download & verify GitHub Actions Runner
########################################
if [ ! -f "./run.sh" ]; then
  echo "Downloading GitHub Actions runner v${RUNNER_VERSION}..."
  curl -fsSL -o "${TARBALL}" \
    "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/${TARBALL}"

  echo "Verifying runner checksum..."
  echo "${TARBALL_SHA256}  ${TARBALL}" | shasum -a 256 -c -

  echo "Extracting runner..."
  tar xzf "${TARBALL}"
fi

########################################
# Fetch metadata (secure)
########################################
GITHUB_URL="$(curl -fsS -H "${META_HEADER}" "${META_URL}/github_url")"
RUNNER_TOKEN="$(curl -fsS -H "${META_HEADER}" "${META_URL}/runner_token")"

########################################
# Validate metadata
########################################
if [ -z "${GITHUB_URL}" ]; then
  echo "ERROR: github_url metadata is missing" >&2
  exit 1
fi

if [ -z "${RUNNER_TOKEN}" ]; then
  echo "ERROR: runner_token metadata is missing" >&2
  exit 1
fi

########################################
# Configure runner
########################################
RUNNER_NAME="runner-$(hostname)-$(date +%s)"

echo "Configuring GitHub Actions runner..."
./config.sh \
  --url "${GITHUB_URL}" \
  --token "${RUNNER_TOKEN}" \
  --name "${RUNNER_NAME}" \
  --labels "${LABELS}" \
  --unattended

########################################
# Run the runner (single job) & shutdown
########################################
echo "Starting runner..."
./run.sh --once || true

echo "Job completed. Shutting down VM..."
shutdown -h now
