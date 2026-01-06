
#!/usr/bin/env bash
set -euo pipefail

# Example: Fetch metadata (GCE)
RUNNER_TOKEN=$(curl -fsS -H "Metadata-Flavor: Google" \
  "http://metadata.google.internal/computeMetadata/v1/instance/attributes/runner_token")
GITHUB_URL=$(curl -fsS -H "Metadata-Flavor: Google" \
  "http://metadata.google.internal/computeMetadata/v1/instance/attributes/github_url")
RUNNER_LABELS=$(curl -fsS -H "Metadata-Flavor: Google" \
  "http://metadata.google.internal/computeMetadata/v1/instance/attributes/runner_labels")

# Download runner, configure, and start as a service
./config.sh \
  --url "${GITHUB_URL}" \
  --token "${RUNNER_TOKEN}" \
  --name "${HOSTNAME}" \
  --labels "${RUNNER_LABELS}" \
  --unattended

sudo ./svc.sh install
sudo ./svc.sh start
``
