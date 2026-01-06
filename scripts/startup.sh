#!/bin/bash
set -euxo pipefail

LOG_FILE="/var/log/github-runner-startup.log"
exec > >(tee -a ${LOG_FILE}) 2>&1

echo "================================================="
echo "$(date) : 🚀 Startup script started"
echo "================================================="

echo "$(date) : 🔄 Updating system packages"
apt-get update -y

echo "$(date) : 📦 Installing required packages (curl, jq, git, nginx)"
apt-get install -y curl jq git nginx

echo "$(date) : 📁 Creating actions-runner directory"
mkdir -p /actions-runner
cd /actions-runner

echo "$(date) : 🔍 Fetching latest GitHub Runner version"
RUNNER_VERSION=$(curl -s https://api.github.com/repos/actions/runner/releases/latest | jq -r .tag_name)
echo "$(date) : ✅ Latest Runner version: ${RUNNER_VERSION}"

echo "$(date) : ⬇️ Downloading GitHub Runner"
curl -L -o runner.tar.gz \
https://github.com/actions/runner/releases/download/${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz

echo "$(date) : 📦 Extracting Runner archive"
tar xzf runner.tar.gz

echo "$(date) : 🔐 Configuring GitHub Self-Hosted Runner"
./config.sh \
  --url https://github.com/${github_owner}/${github_repo} \
  --token ${runner_token} \
  --unattended \
  --name gcp-runner \
  --labels gcp,self-hosted

echo "$(date) : 🧩 Installing runner as a system service"
./svc.sh install

echo "$(date) : ▶️ Starting GitHub Runner service"
./svc.sh start

echo "$(date) : 🌐 Configuring NGINX web server"
echo "<h1>GitHub Runner Deployment Successful</h1>" > /var/www/html/index.html

systemctl enable nginx
systemctl restart nginx

echo "$(date) : ✅ NGINX started successfully"

echo "================================================="
echo "$(date) : ✅ Startup script completed successfully"
echo "================================================="
