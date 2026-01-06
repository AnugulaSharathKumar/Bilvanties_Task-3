#!/bin/bash
set -euo pipefail

# Install and configure GitHub Actions self-hosted runner
RUNNER_VERSION="2.330.0"
RUNNER_DIR="/opt/actions-runner"
LABELS="private,ubuntu,linux,gcp"
TARBALL="actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz"
TARBALL_SHA256="af5c33fa94f3cc33b8e97937939136a6b04197e6dadfcfb3b6e33ae1bf41e79a"

apt-get update -y
apt-get install -y curl tar jq git perl

mkdir -p "$RUNNER_DIR"
cd "$RUNNER_DIR"

if [ ! -f "./run.sh" ]; then
  curl -L -o "${TARBALL}" "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/${TARBALL}"
  echo "${TARBALL_SHA256}  ${TARBALL}" | shasum -a 256 -c -
  tar xzf "${TARBALL}"
fi

META="http://metadata.google.internal/computeMetadata/v1/instance/attributes"
HDR="Metadata-Flavor: Google"

GITHUB_URL="$(curl -fsS -H "$HDR" "${META}/github_url" 2>/dev/null || true)"
RUNNER_TOKEN="$(curl -fsS -H "$HDR" "${META}/runner_token" 2>/dev/null || true)"

# Require metadata values; fail fast to avoid accidental use of hard-coded tokens
if [ -z "${GITHUB_URL}" ]; then
  echo "ERROR: github_url metadata is missing. Provide it via instance metadata or var.github_repo." >&2
  exit 1
fi
if [ -z "${RUNNER_TOKEN}" ]; then
  echo "ERROR: runner_token metadata is missing. Provide a registration token via instance metadata or var.runner_token." >&2
  exit 1
fi

RUNNER_NAME="runner-$(hostname)-$(date +%s)"

# Register the runner (unattended)
./config.sh --url "${GITHUB_URL}" --token "${RUNNER_TOKEN}" --name "${RUNNER_NAME}" --labels "${LABELS}" --unattended

# Start the runner; when it exits (job done), shut down the VM
./run.sh || true

shutdown -h now
