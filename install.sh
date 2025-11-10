#!/usr/bin/env bash
set -e

echo "[1/7] Updating system..."
sudo apt update && sudo apt upgrade -y

echo "[2/7] Installing dependencies..."
sudo apt install -y curl git unzip build-essential pkg-config libssl-dev

echo "[3/7] Installing Docker..."
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
| sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu \
$(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
| sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

echo "[4/7] Cloning rl-swarm repo..."
if [ ! -d "/home/gensyn/rl_swarm" ]; then
    sudo mkdir -p /home/gensyn
    cd /home/gensyn
    sudo git clone https://github.com/gensyn-ai/rl-swarm rl_swarm
else
    echo "rl_swarm folder already exists → skip"
fi

echo "[5/7] Checking swarm.pem..."
if [ ! -f "/home/gensyn/rl_swarm/keys/swarm.pem" ]; then
    echo ""
    echo "❌ swarm.pem NOT FOUND!"
    echo "⛔ Upload your swarm.pem to:"
    echo "/home/gensyn/rl_swarm/keys/swarm.pem"
    echo ""
    echo "Then rerun installer:"
    echo "bash <(curl -s https://raw.githubusercontent.com/deklan400/deklan-autoinstall/main/install.sh)"
    exit 1
fi

echo "[6/7] Installing systemd service..."
sudo cp /home/gensyn/rl_swarm/gensyn.service /etc/systemd/system/gensyn.service
sudo systemctl daemon-reload
sudo systemctl enable --now gensyn

echo "[7/7] DONE ✅"
systemctl status gensyn --no-pager
