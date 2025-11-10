#!/usr/bin/env bash
set -euo pipefail

###########################################################################
#   GENSYN RL-SWARM — CLEAN REINSTALL
#   by Deklan & GPT-5
###########################################################################

SERVICE_NAME="gensyn"
RL_DIR="/root/rl_swarm"
KEY_DIR="/root/deklan"
COMPOSE="docker compose"

GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
CYAN="\e[36m"
NC="\e[0m"

msg()   { echo -e "${GREEN}✅ $1${NC}"; }
warn()  { echo -e "${YELLOW}⚠ $1${NC}"; }
err()   { echo -e "${RED}❌ $1${NC}"; }
info()  { echo -e "${CYAN}$1${NC}"; }

echo -e "
${CYAN}=====================================================
 🔁  REINSTALL RL-SWARM NODE (SAFE)
=====================================================${NC}
"

###########################################################################
#   CHECK ROOT
###########################################################################
if [[ $EUID -ne 0 ]]; then
    err "Run as ROOT!"
    exit 1
fi

###########################################################################
#   STOP SERVICE
###########################################################################
info "[1/5] Stopping service…"
systemctl stop "$SERVICE_NAME" >/dev/null 2>&1 || warn "Already stopped"
systemctl disable "$SERVICE_NAME" >/dev/null 2>&1 || true

###########################################################################
#   UPDATE RL-SWARM
###########################################################################
info "[2/5] Updating RL-Swarm…"

if [[ -d "$RL_DIR/.git" ]]; then
    pushd "$RL_DIR" >/dev/null
    read -p "Run git pull update? [Y/n] > " ans || true
    if [[ ! "$ans" =~ ^[Nn]$ ]]; then
        git pull || warn "git pull failed"
        msg "Repo updated ✅"
    else
        warn "Skip update"
    fi
    popd >/dev/null
else
    err "RL-Swarm repo missing → cannot update"
fi

###########################################################################
#   KEYS
###########################################################################
info "[3/5] Checking keys…"

if [[ ! -d "$KEY_DIR" ]]; then
    err "Key folder missing → $KEY_DIR"
fi

rm -f "$RL_DIR/keys"
ln -s "$KEY_DIR" "$RL_DIR/keys"
msg "Symlink refreshed ✅"

###########################################################################
#   DOCKER
###########################################################################
info "[4/5] Docker update/build…"

pushd "$RL_DIR" >/dev/null

$COMPOSE pull || warn "Pull failed"
$COMPOSE build swarm-cpu || warn "Build failed"

popd >/dev/null

msg "Docker updated ✅"

###########################################################################
#   START SERVICE
###########################################################################
info "[5/5] Restarting service…"

systemctl daemon-reload
systemctl enable "$SERVICE_NAME" >/dev/null 2>&1 || true
systemctl restart "$SERVICE_NAME" || true

sleep 2

if systemctl is-active --quiet "$SERVICE_NAME"; then
    msg "NODE RUNNING ✅"
else
    err "NODE FAILED → Check logs:"
    echo "journalctl -u $SERVICE_NAME -f"
    exit 1
fi

msg "✅ REINSTALL COMPLETE!"
