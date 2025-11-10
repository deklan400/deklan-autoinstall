#!/usr/bin/env bash
set -euo pipefail

###########################################################################
#   GENSYN RL-SWARM — CLEAN UPDATE
#   by Deklan & GPT-5
###########################################################################

SERVICE_NAME="gensyn"
RL_DIR="/root/rl_swarm"

GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
CYAN="\e[36m"
NC="\e[0m"

msg()  { echo -e "${GREEN}✅ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠ $1${NC}"; }
err()  { echo -e "${RED}❌ $1${NC}"; }
info() { echo -e "${CYAN}$1${NC}"; }

echo -e "
${CYAN}=====================================================
♻  UPDATE RL-SWARM (LIGHT)
=====================================================${NC}
"

###########################################################################
# 1 — STOP SERVICE
###########################################################################
info "[1/4] Stopping service..."
systemctl stop "$SERVICE_NAME" >/dev/null 2>&1 || warn "Service not running"

###########################################################################
# 2 — UPDATE REPO
###########################################################################
info "[2/4] Updating code..."

if [[ -d "$RL_DIR/.git" ]]; then
    pushd "$RL_DIR" >/dev/null
    git pull || warn "git pull failed — continuing"
    popd >/dev/null
    msg "Repo updated ✅"
else
    err "RL-Swarm repo missing → $RL_DIR"
    exit 1
fi

###########################################################################
# 3 — REBUILD (optional)
###########################################################################
read -p "Rebuild Docker images? [Y/n] > " ans || true
if [[ ! "$ans" =~ ^[Nn]$ ]]; then
    info "[3/4] Rebuilding docker..."
    pushd "$RL_DIR" >/dev/null
    docker compose pull || warn "pull failed"
    docker compose build swarm-cpu || warn "build failed"
    popd >/dev/null
    msg "Docker updated ✅"
else
    warn "Skipping rebuild"
fi

###########################################################################
# 4 — START SERVICE
###########################################################################
info "[4/4] Restarting service..."
systemctl daemon-reload
systemctl restart "$SERVICE_NAME" || true

sleep 2

if systemctl is-active --quiet "$SERVICE_NAME"; then
    msg "Node running ✅"
else
    err "Node NOT running ❌"
    echo ""
    echo "Last logs:"
    journalctl -u "$SERVICE_NAME" -n 40 --no-pager
    exit 1
fi

msg "✅ UPDATE COMPLETE"
echo ""
echo "➡ Follow logs:"
echo "   journalctl -u $SERVICE_NAME -f"
