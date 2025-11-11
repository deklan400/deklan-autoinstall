#!/usr/bin/env bash
set -euo pipefail

###########################################################################
#   GENSYN RL-SWARM RESTARTER — v4 (CPU Smart)
#   by Deklan & GPT-5
###########################################################################

SERVICE_NAME="gensyn"
RL_DIR="/root/rl-swarm"
KEY_DIR="/root/deklan"
REQ_KEYS=("swarm.pem" "userData.json" "userApiKey.json")

GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
CYAN="\e[36m"
NC="\e[0m"

say()  { echo -e "${GREEN}✅ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠ $1${NC}"; }
fail() { echo -e "${RED}❌ $1${NC}"; exit 1; }
note() { echo -e "${CYAN}$1${NC}"; }

echo -e "
==================================================
 🔄 Restart — Gensyn RL-Swarm (CPU-only)
==================================================
Time: $(date)
"


###########################################################################
#   Validate service exists
###########################################################################
if ! systemctl list-unit-files | grep -q "^${SERVICE_NAME}\.service"; then
    fail "Service '${SERVICE_NAME}.service' NOT installed"
fi
say "Service exists ✅"


###########################################################################
#   Validate RL-Swarm folder
###########################################################################
[[ -d "$RL_DIR" ]] || fail "RL-Swarm missing → $RL_DIR"
say "RL-Swarm folder OK ✅"


###########################################################################
#   Validate identity
###########################################################################
for k in "${REQ_KEYS[@]}"; do
    [[ -f "$KEY_DIR/$k" ]] || fail "Missing → $KEY_DIR/$k"
done
say "Identity OK ✅"


###########################################################################
#   Enforce keys symlink
###########################################################################
rm -rf "$RL_DIR/keys" 2>/dev/null || true
ln -s "$KEY_DIR" "$RL_DIR/keys"
say "Symlink OK → $RL_DIR/keys → $KEY_DIR"


###########################################################################
#   Cleanup zombie docker containers
###########################################################################
note "[*] Cleanup old docker containers…"
docker ps -aq | xargs -r docker rm -f >/dev/null 2>&1 || true
say "Docker cleanup OK ✅"


###########################################################################
#   Restart service
###########################################################################
note "[*] Restarting service…"
systemctl daemon-reload
systemctl restart "$SERVICE_NAME"
sleep 2

if systemctl is-active --quiet "$SERVICE_NAME"; then
    say "Systemd restart OK ✅"
else
    warn "Systemd restart FAILED"
    fail "Node NOT running ❌"
fi


###########################################################################
#   Print logs
###########################################################################
echo ""
note "[*] Last 30 log lines:"
journalctl -u "$SERVICE_NAME" -n 30 --no-pager || true
echo ""


###########################################################################
#   Tail mode
###########################################################################
if [[ "${1:-}" == "-f" ]]; then
    note "[*] Tailing logs (Ctrl + C exit)…"
    journalctl -u "$SERVICE_NAME" -f
fi

say "Done ✅"
echo "➡ Follow logs:"
echo "   journalctl -u $SERVICE_NAME -f"
