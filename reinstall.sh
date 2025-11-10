#!/usr/bin/env bash
set -e

###########################################################################
#   GENSYN RL-SWARM — REINSTALL
#   by Deklan & GPT-5
###########################################################################

SERVICE_NAME="gensyn"
RL_HOME="/home/gensyn"
RL_DIR="$RL_HOME/rl_swarm"
IDENTITY_DIR="/root/deklan"
KEYS_DIR="$RL_DIR/keys"

GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
CYAN="\e[36m"
NC="\e[0m"

msg()   { echo -e "${GREEN}✅ $1${NC}"; }
warn()  { echo -e "${YELLOW}⚠️ $1${NC}"; }
err()   { echo -e "${RED}❌ $1${NC}"; }
info()  { echo -e "${CYAN}$1${NC}"; }

echo -e "
${CYAN}=====================================================
🔁  REINSTALL RL-SWARM NODE
=====================================================${NC}
"

# stop
info "Stopping service..."
systemctl stop "$SERVICE_NAME" || true

# pull
if [[ -d "$RL_DIR" ]]; then
    info "Git pull code..."
    pushd "$RL_DIR" >/dev/null
    sudo -u gensyn git pull
    popd >/dev/null
else
    err "RL-Swarm not found → cloning repo..."
    sudo -u gensyn git clone https://github.com/gensyn-ai/rl-swarm "$RL_DIR"
fi

# copy ident
info "Copying identity..."
mkdir -p "$KEYS_DIR"
cp "$IDENTITY_DIR"/swarm.pem "$KEYS_DIR"/swarm.pem || true
cp "$IDENTITY_DIR"/userData.json "$KEYS_DIR"/userData.json || true
cp "$IDENTITY_DIR"/userApiKey.json "$KEYS_DIR"/userApiKey.json || true
chmod 600 "$KEYS_DIR/swarm.pem"
chown -R gensyn:gensyn "$KEYS_DIR"

# restart
info "Starting service..."
systemctl daemon-reload
systemctl restart "$SERVICE_NAME"

sleep 2
systemctl status "$SERVICE_NAME" --no-pager || true

msg "✅ REINSTALL COMPLETE"
