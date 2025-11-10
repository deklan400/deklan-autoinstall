#!/usr/bin/env bash
set -euo pipefail

###########################################################################
#   GENSYN RL-SWARM RESTARTER (SMART+) — v3.3
#   by Deklan & GPT-5
###########################################################################

SERVICE_NAME="gensyn"
RL_DIR="/root/rl_swarm"
KEY_DIR="/root/deklan"
REQ_KEYS=("swarm.pem" "userData.json" "userApiKey.json")

COMPOSE_BIN=""

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
 🔄 SMART+ Restart — Gensyn RL-Swarm
==================================================
Time: $(date)
"


###########################################################################
#   Detect docker compose
###########################################################################
if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
    COMPOSE_BIN="docker compose"
elif command -v docker-compose >/dev/null 2>&1; then
    COMPOSE_BIN="docker-compose"
else
    warn "docker compose missing → installing…"
    apt update -y >/dev/null
    apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin >/dev/null
    COMPOSE_BIN="docker compose"
fi
say "compose → $COMPOSE_BIN"


###########################################################################
#   Check service
###########################################################################
if ! systemctl list-unit-files | grep -q "^${SERVICE_NAME}\.service"; then
    fail "Service '${SERVICE_NAME}.service' NOT found"
fi
say "Service exists ✅"


###########################################################################
#   Check RL-Swarm folder
###########################################################################
if [[ ! -d "$RL_DIR" ]]; then
    fail "RL-Swarm missing → $RL_DIR"
fi
say "RL-Swarm folder OK ✅"


###########################################################################
#   Check identity keys
###########################################################################
MISS=0
for k in "${REQ_KEYS[@]}"; do
    if [[ ! -f "$KEY_DIR/$k" ]]; then
        warn "Missing key → $KEY_DIR/$k"
        MISS=1
    fi
done

[[ $MISS == 1 ]] && fail "Identity incomplete → abort restart"
say "Identity OK ✅"


###########################################################################
#   Ensure run_node.sh permission
###########################################################################
if [[ ! -x "$RL_DIR/run_node.sh" ]]; then
    warn "run_node.sh no exec perm → fixing"
    chmod +x "$RL_DIR/run_node.sh"
fi


###########################################################################
#   Clean zombie docker containers
###########################################################################
note "[*] Removing dead docker containers..."
docker ps -aq | xargs -r docker rm -f >/dev/null 2>&1 || true
say "Docker cleanup OK ✅"


###########################################################################
#   Restart systemd
###########################################################################
note "[*] systemctl daemon-reload"
systemctl daemon-reload

note "[*] Restarting service: $SERVICE_NAME"
systemctl restart "$SERVICE_NAME"
sleep 2


###########################################################################
#   First validation
###########################################################################
if systemctl is-active --quiet "$SERVICE_NAME"; then
    say "Systemd restart OK ✅"
else
    warn "Systemd restart FAILED — trying docker compose fallback"

    pushd "$RL_DIR" >/dev/null 2>&1 || true
    $COMPOSE_BIN restart swarm-cpu || warn "compose restart failed"
    popd >/dev/null || true

    sleep 3
fi


###########################################################################
#   Final validate
###########################################################################
if systemctl is-active --quiet "$SERVICE_NAME"; then
    say "Node RUNNING ✅"
else
    fail "Node still NOT running ❌"
fi


###########################################################################
#   Logs
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
else
    say "Done ✅"
    echo "➡ Follow logs:"
    echo "   journalctl -u $SERVICE_NAME -f"
fi
