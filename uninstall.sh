#!/usr/bin/env bash
set -euo pipefail

SERVICE_NAME="gensyn"
RL_DIR="/home/gensyn/rl_swarm"
KEYS_DIR="$RL_DIR/keys"
IDENTITY_DIR="/root/deklan"

echo "====================================================="
echo " 🧹 GENSYN RL-SWARM — UNINSTALL SCRIPT"
echo "====================================================="
echo "Time: $(date)"
echo ""

# -----------------------------------------------------
# STOP SERVICE
# -----------------------------------------------------
echo "[1/6] Stopping & disabling systemd service..."

systemctl stop "$SERVICE_NAME" 2>/dev/null || true
systemctl disable "$SERVICE_NAME" 2>/dev/null || true

rm -f "/etc/systemd/system/$SERVICE_NAME.service"
systemctl daemon-reload
echo "✅ Service disabled + removed"
echo ""

# -----------------------------------------------------
# REMOVE RL-SWARM DIR
# -----------------------------------------------------
echo "[2/6] Removing RL-Swarm directory..."

if [[ -d "$RL_DIR" ]]; then
    rm -rf "$RL_DIR"
    echo "✅ Deleted: $RL_DIR"
else
    echo "ℹ️  RL-Swarm not found: $RL_DIR"
fi
echo ""

# -----------------------------------------------------
# REMOVE IDENTITY FILES
# -----------------------------------------------------
echo "[3/6] Clearing identity folder..."

if [[ -d "$IDENTITY_DIR" ]]; then
    rm -rf "$IDENTITY_DIR"
    echo "✅ Deleted identity: $IDENTITY_DIR"
else
    echo "ℹ️  Identity folder not found: $IDENTITY_DIR"
fi
echo ""

# -----------------------------------------------------
# CLEAN DOCKER
# -----------------------------------------------------
echo "[4/6] Cleaning Docker containers/images for swarm..."

docker ps -a | grep -i swarm-cpu >/dev/null 2>&1 && \
    docker rm -f $(docker ps -a | grep -i swarm-cpu | awk '{print $1}') >/dev/null 2>&1 || true

docker images | grep -i swarm >/dev/null 2>&1 && \
    docker rmi -f $(docker images | grep -i swarm | awk '{print $3}') >/dev/null 2>&1 || true

echo "✅ Basic Docker cleanup done"
echo ""

# -----------------------------------------------------
# OPTIONAL FULL DOCKER WIPE
# -----------------------------------------------------
echo "[5/6] OPTIONAL: Full Docker wipe"
read -p "Delete ALL docker data? (y/N) > " confirm
if [[ "${confirm,,}" == "y" ]]; then
    echo "⚠ FULL docker cleanup..."
    systemctl stop docker || true
    systemctl disable docker || true
    apt purge -y docker* containerd* || true
    rm -rf /var/lib/docker /var/lib/containerd
    echo "✅ Docker fully removed"
else
    echo "⏭ Skip full Docker removal"
fi
echo ""

# -----------------------------------------------------
# PURGE LOGS
# -----------------------------------------------------
echo "[6/6] Cleaning logs..."
journalctl --vacuum-time=1s >/dev/null 2>&1 || true
echo "✅ Logs cleaned"
echo ""

echo "====================================================="
echo " ✅ UNINSTALL COMPLETE"
echo "====================================================="
echo ""
