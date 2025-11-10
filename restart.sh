#!/usr/bin/env bash
set -euo pipefail

SERVICE_NAME="gensyn"
RL_DIR="/home/gensyn/rl_swarm"

echo "=================================================="
echo " 🔄 Restarting Gensyn RL-Swarm Node"
echo "=================================================="
echo "Time: $(date)"
echo ""

# ---------------------------------------
# CHECK SERVICE
# ---------------------------------------
if ! systemctl list-unit-files | grep -q "$SERVICE_NAME"; then
    echo "❌ ERROR: Service '$SERVICE_NAME' not found"
    exit 1
fi

# ---------------------------------------
# STOP ZOMBIE DOCKER
# ---------------------------------------
echo "[*] Cleaning zombies…"
docker ps -aq | xargs -r docker rm -f >/dev/null 2>&1 || true

# ---------------------------------------
# RESTART
# ---------------------------------------
echo "[*] Restarting service: $SERVICE_NAME"
systemctl restart "$SERVICE_NAME"

sleep 2

# ---------------------------------------
# STATUS
# ---------------------------------------
STATUS=$(systemctl is-active "$SERVICE_NAME")

if [[ "$STATUS" == "active" ]]; then
    echo "✅ Service Running"
else
    echo "❌ Service NOT running"
fi

echo ""
systemctl status "$SERVICE_NAME" --no-pager || true
echo ""

# ---------------------------------------
# QUICK ERROR CHECK
# ---------------------------------------
echo "[*] Checking recent logs (last 20 lines)…"
journalctl -u "$SERVICE_NAME" -n 20 --no-pager || true
echo ""

# ---------------------------------------
# Optional tailing
# ---------------------------------------
if [[ "${1:-}" == "-f" ]]; then
    echo "[*] Tail logs (Ctrl+C to exit)"
    journalctl -u "$SERVICE_NAME" -f
else
    echo "✅ Done!"
    echo "➡ To follow logs:   journalctl -u $SERVICE_NAME -f"
fi
