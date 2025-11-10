#!/usr/bin/env bash
set -euo pipefail

###########################################################################
#   GENSYN RL-SWARM — REINSTALL (UPGRADED)
#   by Deklan & GPT-5
###########################################################################

SERVICE_NAME="gensyn"
RL_HOME="/home/gensyn"
RL_DIR="$RL_HOME/rl_swarm"
IDENTITY_DIR="/root/deklan"
KEYS_DIR="$RL_DIR/keys"
COMPOSE="/usr/bin/docker compose"

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

###########################################################################
#   CHECK
###########################################################################
if [[ $EUID -ne 0 ]]; then
    err "Run as ROOT!"
    exit 1
fi

if [[ ! -d "$IDENTITY_DIR" ]]; then
    err "Identity folder not found → $IDENTITY_DIR"
    exit 1
fi

###########################################################################
#   STOP SERVICE
###########################################################################
info "[1/5] Stopping service…"
systemctl stop "$SERVICE_NAME" || warn "Service already stopped"
systemctl disable "$SERVICE_NAME" || true


###########################################################################
#   UPDATE rl-swarm REPO
###########################################################################
info "[2/5] Updating RL-Swarm code…"

if [[ -d "$RL_DIR/.git" ]]; then
    pushd "$RL_DIR" >/dev/null
    sudo -u gensyn git fetch --all
    sudo -u gensyn git reset --hard origin/main
    popd >/dev/null
    msg "Repo updated ✅"
else
    warn "Repo missing → re-cloning…"
    rm -rf "$RL_DIR" || true
    sudo -u gensyn git clone https://github.com/gensyn-ai/rl-swarm "$RL_DIR"
    msg "Repo cloned ✅"
fi


###########################################################################
#   COPY IDENTITY
###########################################################################
info "[3/5] Copying identity…"

mkdir -p "$KEYS_DIR"

for f in swarm.pem userApiKey.json userData.json; do
    if [[ -f "$IDENTITY_DIR/$f" ]]; then
        cp "$IDENTITY_DIR/$f" "$KEYS_DIR/$f"
        msg "Copied → $f"
    else
        warn "Missing identity file → $f"
    fi
done

chmod 600 "$KEYS_DIR/swarm.pem" || true
chown -R gensyn:gensyn "$KEYS_DIR"
msg "Identity OK ✅"


###########################################################################
#   DOCKER BUILD / PULL
###########################################################################
info "[4/5] Rebuilding Docker…"

cd "$RL_DIR"

# Pull
$COMPOSE pull || warn "Pull failed, continue…"

# Build
$COMPOSE build swarm-cpu || warn "Build failed, continue…"

msg "Docker rebuild OK ✅"


###########################################################################
#   START SERVICE
###########################################################################
info "[5/5] Starting Node…"

systemctl daemon-reload
systemctl enable "$SERVICE_NAME" || true
systemctl restart "$SERVICE_NAME"

sleep 2

if systemctl is-active --quiet "$SERVICE_NAME"; then
    msg "NODE RUNNING ✅"
else
    err "NODE FAILED → Check logs:"
    echo "journalctl -u $SERVICE_NAME -f"
fi

msg "✅ REINSTALL COMPLETE!"
