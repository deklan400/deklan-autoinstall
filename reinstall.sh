#!/usr/bin/env bash
set -euo pipefail

SERVICE_NAME="gensyn"
RL_DIR="/home/gensyn/rl_swarm"
IDENTITY_DIR="/root/deklan"
KEYS_DIR="$RL_DIR/keys"
REPO_URL="https://github.com/gensyn-ai/rl-swarm"

echo ""
echo "====================================================="
echo " 🔁 Reinstall Gensyn RL-Swarm"
echo "====================================================="
echo ""

##################################################################
# 1) STOP + DISABLE SERVICE
##################################################################
echo "[1/7] Stopping systemd service..."

systemctl stop "$SERVICE_NAME" 2>/dev/null || true
systemctl disable "$SERVICE_NAME" 2>/dev/null || true

rm -f "/etc/systemd/system/$SERVICE_NAME.service"
systemctl daemon-reload
echo "✅ Systemd disabled"
echo ""

##################################################################
# 2) DELETE OLD RL-SWARM
##################################################################
echo "[2/7] Removing old rl-swarm directory..."

if [[ -d "$RL_DIR" ]]; then
    rm -rf "$RL_DIR"
    echo "✅ Removed old rl-swarm"
else
    echo "ℹ️  No existing rl-swarm found"
fi
echo ""

##################################################################
# 3) CHECK IDENTITY FILES
##################################################################
echo "[3/7] Checking identity files..."

REQUIRED=("swarm.pem" "userApiKey.json" "userData.json")
for f in "${REQUIRED[@]}"; do
    if [[ ! -f "$IDENTITY_DIR/$f" ]]; then
        echo "❌ Missing: $IDENTITY_DIR/$f"
        MISSING=1
    else
        echo "✅ Found: $f"
    fi
done

if [[ "${MISSING:-0}" -eq 1 ]]; then
    echo ""
    echo "⚠️  Missing identity files!"
    echo "➡ Copy them to: $IDENTITY_DIR"
    exit 1
fi

echo "✅ Identity OK"
echo ""

##################################################################
# 4) CLONE RL-SWARM
##################################################################
echo "[4/7] Cloning rl-swarm repo..."

mkdir -p /home/gensyn
cd /home/gensyn
git clone "$REPO_URL" rl_swarm

echo "✅ Cloned"
echo ""

##################################################################
# 5) COPY KEYS
##################################################################
echo "[5/7] Copying identity to keys..."

mkdir -p "$KEYS_DIR"
for f in "${REQUIRED[@]}"; do
    cp "$IDENTITY_DIR/$f" "$KEYS_DIR/$f"
done
chmod 600 "$KEYS_DIR/swarm.pem"

echo "✅ Identity copied to $KEYS_DIR"
echo ""

##################################################################
# 6) INSTALL SYSTEMD
##################################################################
echo "[6/7] Installing gensyn.service..."

curl -s -o /etc/systemd/system/gensyn.service \
    https://raw.githubusercontent.com/deklan400/deklan-autoinstall/main/gensyn.service

systemctl daemon-reload
systemctl enable --now gensyn
echo "✅ Service enabled"
echo ""

##################################################################
# 7) CHECK STATUS
##################################################################
echo "[7/7] ✅ Done"

systemctl status gensyn --no-pager || true
echo ""
echo "Logs:"
echo "journalctl -u gensyn -f"
echo ""
