#!/bin/bash
set -euo pipefail
...
RUNNER_VERSION="2.317.0"
RUNNER_DIR="/opt/actions-runner"
LABELS="private,ubuntu,linux,gcp"
...
GITHUB_URL="$(curl -fsS -H "$HDR" "${META}/github_url")"
RUNNER_TOKEN="$(curl -fsS -H "$HDR" "${META}/runner_token")"
...
./config.sh --url "${GITHUB_URL}" --token "${RUNNER_TOKEN}" --ephemeral
./run.sh --once
shutdown -h now
