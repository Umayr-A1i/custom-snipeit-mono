#!/bin/bash
set -e

# Update system
apt-get update -y
apt-get install -y ca-certificates curl gnupg awscli snapd

##############################################
# Install SSM Agent (Required for CI/CD)
##############################################
snap install amazon-ssm-agent --classic
systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service
systemctl start snap.amazon-ssm-agent.amazon-ssm-agent.service

##############################################
# Install Docker
##############################################
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Enable Docker
systemctl enable docker
systemctl start docker

# Allow ubuntu user to run docker
usermod -aG docker ubuntu

##############################################
# Install Docker Compose v2 standalone binary
##############################################
curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) \
 -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

##############################################
# Create deploy directory for Snipe-IT stack
##############################################
mkdir -p /opt/snipeit
chown -R ubuntu:ubuntu /opt/snipeit
