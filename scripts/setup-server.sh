#!/usr/bin/env bash
set -euo pipefail

# Node.js LTS (v22)
if ! command -v node &>/dev/null; then
  curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
  sudo apt-get install -y nodejs
fi

# System packages
sudo apt-get install -y nginx git ufw jq curl

# Corepack
sudo corepack enable

# System user
if ! id africair &>/dev/null; then
  sudo useradd --system --no-create-home --shell /usr/sbin/nologin africair
fi

# Config directory and non-secret env file
sudo mkdir -p /etc/africair
if [[ ! -f /etc/africair/api.env ]]; then
  sudo tee /etc/africair/api.env > /dev/null <<'EOF'
APP_ENV=staging
APP_VERSION=1.0.0
ANNOUNCEMENT_TEXT=Welcome to the AfricAir staging server
ANNOUNCEMENT_LEVEL=info
SERVICE_FEE_USD=9
DEFAULT_CURRENCY=KES
EOF
fi
sudo chown root:africair /etc/africair/api.env
sudo chmod 0640 /etc/africair/api.env

# Directory layout
sudo mkdir -p /opt/africair/releases /opt/africair/shared
if [ ! -L /opt/africair/current ]; then
  sudo ln -s /opt/africair/releases /opt/africair/current
fi
sudo chown -R africair:africair /opt/africair

# UFW
sudo ufw allow OpenSSH
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw --force enable

echo "Setup complete."
