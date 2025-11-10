#!/usr/bin/env bash
set -euo pipefail

###########################################################################
#   GENSYN RL-SWARM — UPDATE NODE (LIGHT)
#   by Deklan & GPT-5
###########################################################################

SERVICE_NAME="gensyn"
RL_HOME="/home/gensyn"
RL_DIR="$RL_HOME/rl_swarm"

GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
CYAN="\e[36m"
NC="\e[0m"

msg()  { echo -e "${GREEN}✅ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠️ $1${NC}"; }
err()  { echo -e "${RED}❌ $1${NC}"; }
info() { echo -e "${CYAN}$1${NC}"; }

echo -e "
${CYAN}=====================================================
♻  UPDATE RL-SWARM (LIGHT)
=====================================================${NC}
"

# stop
info "Stopping service..."
systemctl stop "$SERVICE_NAME" 2>/dev/null || warn "Service not running"

# update
if [[ -d "$RL_DIR" ]]; then
    info "Updating code..."
    pushd "$RL_DIR" >/dev/null

    sudo -u gensyn git fetch --all
    sudo -u gensyn git reset --hard origin/main || {
        err "git update failed!"
        exit 1
    }

    popd >/dev/null
else
    err "RL-Swarm directory missing → clone needed!"
    exit 1
fi

# restart
info "Restarting service..."
systemctl daemon-reload || true
systemctl start "$SERVICE_NAME"

sleep 2

if systemctl is-active --quiet "$SERVICE_NAME"; then
    msg "Node running ✅"
else
    err "Node still NOT running ❌"
    echo ""
    echo "Last logs:"
    journalctl -u "$SERVICE_NAME" -n 40 --no-pager
fi

msg "✅ UPDATE COMPLETE"
