#!/bin/bash
set -euxo pipefail

# ====================================================
# STEP 0: LOG SETUP
# Purpose: Capture all startup activity
# ====================================================
LOG_FILE="/var/log/github-runner-startup.log"
exec > >(tee -a ${LOG_FILE}) 2>&1

echo "================================================="
echo "$(date) : STEP 0 - VM BOOT & STARTUP SCRIPT STARTED"
echo "================================================="


# ====================================================
# STEP 1: OS PREPARATION
# Purpose: Prepare VM with required packages
# ====================================================
echo "$(date) : STEP 1 - Updating OS packages"
apt-get update -y

echo "$(date) : STEP 1 - Installing required packages"
apt-get install -y curl jq git nginx


# ====================================================
# STEP 2: RUNNER DIRECTORY SETUP
# Purpose: Dedicated GitHub runner directory
# ====================================================
echo "$(date) : STEP 2 - Creating runner directory"
mkdir -p /actions-runner
cd /actions-runner


# ====================================================
# STEP 3: DOWNLOAD GITHUB RUNNER
# Purpose: Fetch latest official GitHub runner
# ====================================================
echo "$(date) : STEP 3 - Fetching latest runner version"
RUNNER_VERSION=$(curl -s https://api.github.com/repos/actions/runner/releases/latest | jq -r .tag_name)
echo "$(date) : Runner version: ${RUNNER_VERSION}"

echo "$(date) : Downloading runner binary"
curl -L -o runner.tar.gz \
https://github.com/actions/runner/releases/download/${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz

echo "$(date) : Extracting runner"
tar xzf runner.tar.gz


# ====================================================
# STEP 4: REGISTER RUNNER WITH GITHUB
# Purpose: Make VM visible to GitHub Actions
# ====================================================
echo "$(date) : STEP 4 - Registering runner with GitHub"
./config.sh \
  --url https://github.com/${github_owner}/${github_repo} \
  --token ${runner_token} \
  --unattended \
  --name gcp-self-hosted-runner \
  --labels gcp,self-hosted


# ====================================================
# STEP 5: START RUNNER SERVICE
# Purpose: Runner must be ONLINE before pipeline starts
# ====================================================
echo "$(date) : STEP 5 - Installing runner service"
./svc.sh install

echo "$(date) : STEP 5 - Starting runner service"
./svc.sh start


# ====================================================
# STEP 6: START WEB APPLICATION (NGINX)
# Purpose: Example application for deployment
# ====================================================
echo "$(date) : STEP 6 - Configuring NGINX"
echo "<h1>GitHub Self-Hosted Runner is READY</h1>" > /var/www/html/index.html

systemctl enable nginx
systemctl restart nginx


# ====================================================
# STEP 7: WAIT STATE
# Purpose: VM stays idle waiting for GitHub job
# ====================================================
echo "================================================="
echo "$(date) : STEP 7 - STARTUP COMPLETE"
echo "$(date) : Runner is ONLINE and WAITING for pipeline"
echo "================================================="
