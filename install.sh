#!/usr/bin/env bash
set -e

####################################################################
#   SETTINGS
####################################################################
IDENTITY_DIR="/root/deklan"
REQUIRED_FILES=("swarm.pem" "userData.json" "userApiKey.json")
RL_DIR="/home/gensyn/rl_swarm"
KEYS_DIR="$RL_DIR/keys"

echo ""
echo "====================================================="
echo " 🔥 Gensyn RL-Swarm Auto-Installer"
echo "====================================================="
echo ""

####################################################################
#   CHECK IDENTITY FILES
####################################################################
echo "[1/9] Checking identity files..."
mkdir -p "$IDENTITY_DIR"

MISSING=0
for FILE in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$IDENTITY_DIR/$FILE" ]; then
        echo "❌ Missing: $IDENTITY_DIR/$FILE"
        MISSING=1
    else
        echo "✅ Found: $FILE"
    fi
done

if [ "$MISSING" -eq 1 ]; then
    echo ""
    echo "⚠️  One or more identity files are missing."
    echo "➡ Please put the following files inside: $IDENTITY_DIR"
    echo ""
    echo "Required:"
    echo " - swarm.pem"
    echo " - userData.json"
    echo " - userApiKey.json"
    echo ""
    echo "Then rerun:"
    echo "bash <(curl -s https://raw.githubusercontent.com/deklan400/deklan-autoinstall/main/install.sh)"
    exit 1
fi


####################################################################
#   UPDATE SYSTEM
####################################################################
echo ""
echo "[2/9] Updating system..."
sudo apt update && sudo apt upgrade -y


####################################################################
#   INSTALL DEPENDENCIES
####################################################################
echo ""
echo "[3/9] Installing dependencies..."
sudo apt install -y curl git unzip build-essential pkg-config libssl-dev screen


####################################################################
#   INSTALL DOCKER
####################################################################
echo ""
echo "[4/9] Installing Docker..."

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


####################################################################
#   CLONE rl-swarm
####################################################################
echo ""
echo "[5/9] Cloning rl-swarm repo..."

if [ ! -d "$RL_DIR" ]; then
    sudo mkdir -p /home/gensyn
    cd /home/gensyn
    sudo git clone https://github.com/gensyn-ai/rl-swamp rl_swarm
else
    echo "✅ rl_swarm already exists → skip"
fi


####################################################################
#   COPY IDENTITY (PEM + API + DATA)
####################################################################
echo ""
echo "[6/9] Copying identity files..."

sudo mkdir -p "$KEYS_DIR"
for FILE in "${REQUIRED_FILES[@]}"; do
    sudo cp "$IDENTITY_DIR/$FILE" "$KEYS_DIR/$FILE"
done

chmod 600 "$KEYS_DIR/swarm.pem"

echo "✅ Identity OK → copied to $KEYS_DIR"


####################################################################
#   INSTALL SYSTEMD SERVICE
####################################################################
echo ""
echo "[7/9] Installing systemd service..."

sudo curl -s -o /etc/systemd/system/gensyn.service \
    https://raw.githubusercontent.com/deklan400/deklan-autoinstall/main/gensyn.service

sudo systemctl daemon-reload
sudo systemctl enable --now gensyn


####################################################################
#   FINISH
####################################################################
echo ""
echo "====================================================="
echo " ✅ INSTALLATION COMPLETE"
echo "====================================================="
echo ""
systemctl status gensyn --no-pager
echo ""
echo "To view logs:"
echo "journalctl -u gensyn -f"
