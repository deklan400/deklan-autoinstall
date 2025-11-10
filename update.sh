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
    info "Git pulling latest code..."
    pushd "$RL_DIR" >/dev/null
    sudo -u gensyn git pull
    popd >/dev/null
else
    err "RL-Swarm directory missing → clone needed!"
    exit 1
fi

# restart
info "Restarting service..."
systemctl daemon-reload
systemctl start "$SERVICE_NAME"

sleep 2
systemctl status "$SERVICE_NAME" --no-pager || true

msg "✅ UPDATE COMPLETE"
