#!/usr/bin/env bash
set -euo pipefail

###########################################################################
#   GENSYN RL-SWARM RESTARTER (SAFE)
#   by Deklan & GPT-5
###########################################################################

SERVICE_NAME="gensyn"

GREEN="\e[32m"
RED="\e[31m"
CYAN="\e[36m"
NC="\e[0m"

say()  { echo -e "${GREEN}✅ $1${NC}"; }
fail() { echo -e "${RED}❌ $1${NC}"; exit 1; }
note() { echo -e "${CYAN}$1${NC}"; }

echo "=================================================="
echo " 🔄 Restarting Gensyn RL-Swarm Node"
echo "=================================================="
echo "Time: $(date)"
echo ""

# ---------------------------------------
# CHECK SERVICE
# ---------------------------------------
if ! systemctl list-unit-files | grep -q "$SERVICE_NAME"; then
    fail "Service '$SERVICE_NAME' not found"
fi

# ---------------------------------------
# RESTART SERVICE
# ---------------------------------------
note "[*] Restarting service: $SERVICE_NAME"
systemctl restart "$SERVICE_NAME"

sleep 2

# ---------------------------------------
# STATUS
# ---------------------------------------
STATUS=$(systemctl is-active "$SERVICE_NAME")

if [[ "$STATUS" == "active" ]]; then
    say "Service Running ✅"
else
    fail "Service NOT running"
fi

echo ""
systemctl status "$SERVICE_NAME" --no-pager || true
echo ""

# ---------------------------------------
# QUICK LOG CHECK
# ---------------------------------------
note "[*] Recent logs (last 20 lines)…"
journalctl -u "$SERVICE_NAME" -n 20 --no-pager || true
echo ""

# ---------------------------------------
# Optional tailing
# ---------------------------------------
if [[ "${1:-}" == "-f" ]]; then
    note "[*] Tail logs (Ctrl+C to exit)"
    journalctl -u "$SERVICE_NAME" -f
else
    say "Done ✅"
    echo "➡ To follow logs:"
    echo "   journalctl -u $SERVICE_NAME -f"
fi
