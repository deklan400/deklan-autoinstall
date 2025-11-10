#!/usr/bin/env bash
set -euo pipefail

###########################################################################
#   GENSYN RL-SWARM RESTARTER (SAFE+) — v2
#   by Deklan & GPT-5
###########################################################################

SERVICE_NAME="gensyn"
RL_DIR="/root/rl_swarm"

GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
CYAN="\e[36m"
NC="\e[0m"

say()  { echo -e "${GREEN}✅ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
fail() { echo -e "${RED}❌ $1${NC}"; exit 1; }
note() { echo -e "${CYAN}$1${NC}"; }

echo -e "
==================================================
 🔄 Restarting Gensyn RL-Swarm Node
==================================================
Time: $(date)
"

# =====================================================
# Check service exists
# =====================================================
if ! systemctl list-unit-files | grep -q "^${SERVICE_NAME}"; then
    fail "Service '$SERVICE_NAME' not found"
fi
say "Service exists"


# =====================================================
# Clean zombie docker containers
# =====================================================
note "[*] Cleaning zombie containers…"
docker ps -aq | xargs -r docker rm -f >/dev/null 2>&1 || true
say "Docker cleanup OK"


# =====================================================
# Restart service
# =====================================================
note "[*] Restarting systemd service: $SERVICE_NAME"
systemctl restart "$SERVICE_NAME"
sleep 2


# =====================================================
# Check status
# =====================================================
STATUS="$(systemctl is-active "$SERVICE_NAME")"

if [[ "$STATUS" == "active" ]]; then
    say "Systemd service running ✅"
else
    warn "Systemd restart FAILED — trying docker-compose fallback"

    if [[ -d "$RL_DIR" ]]; then
        pushd "$RL_DIR" >/dev/null 2>&1 || true

        # Try compose variants
        if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
            docker compose restart swarm-cpu || warn "Compose restart failed"
        elif command -v docker-compose >/dev/null 2>&1; then
            docker-compose restart swarm-cpu || warn "Compose restart failed"
        else
            fail "No docker-compose available"
        fi

        popd >/dev/null 2>&1 || true
        sleep 3
    fi
fi


# =====================================================
# Final status
# =====================================================
STATUS="$(systemctl is-active "$SERVICE_NAME")"

if [[ "$STATUS" == "active" ]]; then
    say "Node RUNNING ✅"
else
    fail "Node still NOT running ❌"
fi


# =====================================================
# Recent logs
# =====================================================
echo ""
note "[*] Recent logs (last 30 lines)…"
journalctl -u "$SERVICE_NAME" -n 30 --no-pager || true
echo ""


# =====================================================
# Optional tailing
# =====================================================
if [[ "${1:-}" == "-f" ]]; then
    note "[*] Tailing logs (Ctrl+C to exit)…"
    journalctl -u "$SERVICE_NAME" -f
else
    say "Done ✅"
    echo "➡ To follow logs:"
    echo "   journalctl -u $SERVICE_NAME -f"
fi
