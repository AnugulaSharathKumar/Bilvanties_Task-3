#!/bin/bash
set -e

echo "Updating system..."
apt-get update -y
apt-get install -y curl jq git nginx

echo "Installing GitHub Runner..."
mkdir -p /actions-runner
cd /actions-runner

RUNNER_VERSION=$(curl -s https://api.github.com/repos/actions/runner/releases/latest | jq -r .tag_name)

curl -L -o runner.tar.gz \
https://github.com/actions/runner/releases/download/${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz

tar xzf runner.tar.gz

./config.sh \
  --url https://github.com/${github_owner}/${github_repo} \
  --token ${runner_token} \
  --unattended \
  --name gcp-runner \
  --labels gcp,self-hosted

./svc.sh install
./svc.sh start

echo "Configuring NGINX..."
echo "<h1>Deployment Successful - GitHub Self Hosted Runner</h1>" > /var/www/html/index.html
systemctl enable nginx
systemctl restart nginx

echo "Startup script completed"
