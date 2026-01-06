
#!/usr/bin/env bash
set -euo pipefail

# Read instance metadata (GCE)
MD_HEADER="Metadata-Flavor: Google"
GITHUB_URL=$(curl -fsS -H "$MD_HEADER" http://metadata.google.internal/computeMetadata/v1/instance/attributes/github_url)
RUNNER_TOKEN=$(curl -fsS -H "$MD_HEADER" http://metadata.google.internal/computeMetadata/v1/instance/attributes/runner_token)
RUNNER_LABELS=$(curl -fsS -H "$MD_HEADER" http://metadata.google.internal/computeMetadata/v1/instance/attributes/runner_labels)

# Install dependencies
sudo apt-get update -y
sudo apt-get install -y curl jq

# Download actions runner
cd /opt
sudo mkdir -p actions-runner && sudo chown "$(whoami)":"$(whoami)" actions-runner
cd actions-runner
curl -L -o runner.tar.gz https://github.com/actions/runner/releases/latest/download/actions-runner-linux-x64.tar.gz
tar xzf runner.tar.gz

# Configure and start
./config.sh \
  --url "${GITHUB_URL}" \
  --token "${RUNNER_TOKEN}" \
  --name "$(hostname)" \
  --labels "${RUNNER_LABELS}" \
  --unattended

sudo ./svc.sh install
sudo ./svc.sh start
