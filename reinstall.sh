#!/usr/bin/env bash
set -euo pipefail

###########################################################################
#   GENSYN RL-SWARM — CLEAN REINSTALL v2
#   by Deklan & GPT-5
###########################################################################

SERVICE_NAME="gensyn"
RL_DIR="/root/rl_swarm"
KEY_DIR="/root/deklan"
REPO_URL="https://github.com/gensyn-ai/rl-swarm"
COMPOSE_BIN=""
REQ_KEYS=("swarm.pem" "userData.json" "userApiKey.json")

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
#   FIND docker compose
###########################################################################
if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
    COMPOSE_BIN="docker compose"
elif command -v docker-compose >/dev/null 2>&1; then
    COMPOSE_BIN="docker-compose"
else
    warn "docker compose missing → installing…"
    apt update -y
    apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    COMPOSE_BIN="docker compose"
fi

msg "compose → $COMPOSE_BIN"


###########################################################################
#   STOP SERVICE
###########################################################################
info "[1/6] Stopping service…"
systemctl stop "$SERVICE_NAME" >/dev/null 2>&1 || warn "Already stopped"
systemctl disable "$SERVICE_NAME" >/dev/null 2>&1 || true


###########################################################################
#   ENSURE REPO EXISTS
###########################################################################
info "[2/6] Ensuring RL-Swarm repo…"

if [[ ! -d "$RL_DIR/.git" ]]; then
    warn "RL-Swarm missing → cloning fresh…"
    rm -rf "$RL_DIR"
    git clone "$REPO_URL" "$RL_DIR"
    msg "Repo cloned"
else
    pushd "$RL_DIR" >/dev/null
    read -p "Run git pull update? [Y/n] > " ans || true
    if [[ ! "$ans" =~ ^[Nn]$ ]]; then
        git pull || warn "git pull failed"
        msg "Repo updated ✅"
    else
        warn "Skip update"
    fi
    popd >/dev/null
fi


###########################################################################
#   CHECK & SYNC KEYS
###########################################################################
info "[3/6] Checking identity…"

MISS=0
for k in "${REQ_KEYS[@]}"; do
    [[ ! -f "$KEY_DIR/$k" ]] && err "Missing key → $KEY_DIR/$k" && MISS=1
done

[[ $MISS == 1 ]] && exit 1

rm -rf "$RL_DIR/keys"
ln -s "$KEY_DIR" "$RL_DIR/keys"
msg "Symlink refreshed ✅"


###########################################################################
#   .ENV ENSURE
###########################################################################
info "[4/6] Syncing env…"
if [[ ! -f "$RL_DIR/.env" ]]; then
cat <<EOF > "$RL_DIR/.env"
GENSYN_KEY_DIR=$KEY_DIR
PYTHONUNBUFFERED=1
EOF
msg ".env created"
else
    msg ".env exists → keeping"
fi


###########################################################################
#   DOCKER
###########################################################################
info "[5/6] Updating docker…"

pushd "$RL_DIR" >/dev/null

$COMPOSE_BIN pull || warn "compose pull failed"
$COMPOSE_BIN build swarm-cpu || warn "compose build failed"

popd >/dev/null

msg "Docker updated ✅"


###########################################################################
#   START SERVICE
###########################################################################
info "[6/6] Restarting service…"

systemctl daemon-reload
systemctl enable "$SERVICE_NAME" >/dev/null 2>&1 || true
systemctl restart "$SERVICE_NAME" || true

sleep 2

if systemctl is-active --quiet "$SERVICE_NAME"; then
    msg "NODE RUNNING ✅"
else
    err "NODE FAILED → Check: journalctl -u $SERVICE_NAME -f"
    exit 1
fi

msg "✅ REINSTALL COMPLETE!"
