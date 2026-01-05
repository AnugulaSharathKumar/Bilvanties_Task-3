#!/bin/bash
set -euo pipefail

RUNNER_VERSION="2.317.0"
RUNNER_DIR="/opt/actions-runner"
LABELS="private,ubuntu,linux,gcp"

apt-get update -y
apt-get install -y curl tar jq git

mkdir -p "$RUNNER_DIR"
cd "$RUNNER_DIR"

if [ ! -f "./run.sh" ]; then
  curl -L -o actions-runner.tar.gz \
    "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz"
  tar xzf actions-runner.tar.gz
fi

META="http://metadata.google.internal/computeMetadata/v1/instance/attributes"
HDR="Metadata-Flavor: Google"

GITHUB_URL="$(curl -fsS -H "$HDR" "${META}/github_url")"
RUNNER_TOKEN="$(curl -fsS -H "$HDR" "${META}/runner_token")"

RUNNER_NAME="runner-$(hostname)-$(date +%s)"

# Configure as ephemeral (auto-unregisters after job)
./config.sh \
  --url "${GITHUB_URL}" \
  --token "${RUNNER_TOKEN}" \
  --name "${RUNNER_NAME}" \
  --labels "${LABELS}" \
  --unattended \
  --ephemeral

# Run exactly one job, then exit
./run.sh || true

# Shutdown the VM after job completes
shutdown -h now
