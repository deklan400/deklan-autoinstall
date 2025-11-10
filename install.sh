#!/usr/bin/env bash
set -e

echo "=== Gensyn RL-Swarm Auto-Installer ==="

# 1) Update system
echo "[1/8] Updating system..."
sudo apt update && sudo apt upgrade -y

# 2) Install dependencies
echo "[2/8] Installing dependencies..."
sudo apt install -y \
    curl git unzip build-essential pkg-config libssl-dev screen

# 3) Install Docker
echo "[3/8] Installing Docker..."
sudo apt install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
 | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" |
  sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

sudo apt update -y
sudo apt install -y docker-ce docker-ce-cli containerd.io

echo "[3/8] Testing Docker..."
sudo docker run --rm hello-world || true

# 4) Clone rl-swarm
echo "[4/8] Cloning rl-swarm repo..."
if [ ! -d ~/rl-swarm ]; then
    git clone https://github.com/gensyn-ai/rl-swarm ~/rl-swarm
else
    echo "Folder rl-swarm already exists — skipping"
fi

# 5) Ensure swarm.pem exists
echo "[5/8] Checking for swarm.pem..."

if [ ! -f ~/rl-swarm/keys/swarm.pem ]; then
    echo "⚠ swarm.pem not found!"
    echo "Please upload it to: ~/rl-swarm/keys/swarm.pem"
    mkdir -p ~/rl-swarm/keys
else
    echo "✅ swarm.pem detected."
fi

# 6) Download + copy gensyn.service
echo "[6/8] Installing systemd service..."

curl -s \
 https://raw.githubusercontent.com/deklan400/deklan-autoinstall/main/gensyn.service \
 > /etc/systemd/system/gensyn.service

sudo systemctl daemon-reload
sudo systemctl enable gensyn.service

# 7) Download run_node.sh
echo "[7/8] Updating run_node.sh..."

curl -s \
 https://raw.githubusercontent.com/deklan400/deklan-autoinstall/main/run_node.sh \
 > ~/rl-swarm/run_node.sh

chmod +x ~/rl-swarm/run_node.sh

# 8) Start service
echo "[8/8] Starting Gensyn node..."
sudo systemctl restart gensyn.service
sleep 2
sudo systemctl status gensyn.service --no-pager

echo "✅ DONE — Gensyn RL-Swarm node installed!"
echo "Pegang hidup bro 🔥"
