#!/usr/bin/env bash
set -euo pipefail

###########################################################################
#   GENSYN RL-SWARM INSTALLER v3.1-smart
#   by Deklan & GPT-5
###########################################################################

GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
CYAN="\e[36m"
NC="\e[0m"

IDENTITY_DIR="/root/deklan"
RL_DIR="/root/rl_swarm"
SERVICE_NAME="gensyn"
SERVICE_PATH="/etc/systemd/system/${SERVICE_NAME}.service"
AUTO_REPO="https://raw.githubusercontent.com/deklan400/deklan-autoinstall/main/"

REPO_URL="https://github.com/gensyn-ai/rl-swarm"

REQUIRED_FILES=("swarm.pem" "userData.json" "userApiKey.json")

msg()   { echo -e "${GREEN}✅ $1${NC}"; }
warn()  { echo -e "${YELLOW}⚠ $1${NC}"; }
err()   { echo -e "${RED}❌ $1${NC}"; }
info()  { echo -e "${CYAN}$1${NC}"; }

echo -e "
${CYAN}=====================================================
🔥  GENSYN RL-SWARM INSTALLER — v3.1 SMART
=====================================================${NC}
"

[[ $EUID -ne 0 ]] && err "Run as ROOT!" && exit 1

STEP=1; step() { echo -e "${YELLOW}[$STEP] $1${NC}"; STEP=$((STEP+1)); }

###########################################################################
step "Checking identity files…"
###########################################################################
MISS=0
for FILE in "${REQUIRED_FILES[@]}"; do
    if [[ ! -f "$IDENTITY_DIR/$FILE" ]]; then
        err "Missing → $IDENTITY_DIR/$FILE"
        MISS=1
    else
        msg "Found → $FILE"
    fi
done
[[ $MISS == 1 ]] && err "Missing identity files → abort" && exit 1


###########################################################################
step "Updating system…"
###########################################################################
apt update -y && apt upgrade -y
msg "System updated ✅"


###########################################################################
step "Installing dependencies…"
###########################################################################
apt install -y curl git unzip build-essential pkg-config libssl-dev screen jq nano
msg "Deps OK ✅"


###########################################################################
step "Install Docker (if missing)…"
###########################################################################
if ! command -v docker >/dev/null 2>&1; then
    info "Installing Docker…"
    install -m 0755 -d /etc/apt/keyrings

    curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

    echo \
"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu \
$(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
> /etc/apt/sources.list.d/docker.list

    apt update
    apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    msg "Docker installed ✅"
else
    msg "Docker OK ✅"
fi

systemctl enable --now docker || true


###########################################################################
step "Setup RL-Swarm repo…"
###########################################################################
if [[ ! -d "$RL_DIR" ]]; then
    info "RL-Swarm not found → cloning…"
    git clone "$REPO_URL" "$RL_DIR"
    msg "RL-Swarm cloned ✅"
else
    info "RL-Swarm exists → verifying…"
    pushd "$RL_DIR" >/dev/null
    if git status >/dev/null 2>&1; then
        msg "Git repo OK → running git pull…"
        git pull || warn "git pull failed"
    else
        warn "RL-Swarm exists but NOT git repo → skipping update"
    fi
    popd >/dev/null
    msg "RL-Swarm repo verified ✅"
fi


###########################################################################
step "Link identity → /root/rl_swarm/keys"
###########################################################################
rm -rf "$RL_DIR/keys" 2>/dev/null || true
ln -s "$IDENTITY_DIR" "$RL_DIR/keys"
msg "Symlink OK ✅"


###########################################################################
step "Generate/validate .env…"
###########################################################################
if [[ ! -f "$RL_DIR/.env" ]]; then
    cat <<EOF > "$RL_DIR/.env"
GENSYN_KEY_DIR=$IDENTITY_DIR
PYTHONUNBUFFERED=1
EOF
    msg ".env created ✅"
else
    msg ".env exists → using existing ✅"
fi


###########################################################################
step "Docker build/pull…"
###########################################################################
pushd "$RL_DIR" >/dev/null

if docker compose version >/dev/null 2>&1; then
    COMPOSE="docker compose"
else
    COMPOSE="docker-compose"
fi

$COMPOSE pull || warn "docker pull failed"
$COMPOSE build swarm-cpu || warn "docker build failed"

popd >/dev/null
msg "Docker ready ✅"


###########################################################################
step "Install gensyn.service…"
###########################################################################
curl -s -o "$SERVICE_PATH" "${AUTO_REPO}gensyn.service"
chmod 644 "$SERVICE_PATH"

systemctl daemon-reload
systemctl enable --now "$SERVICE_NAME"
msg "gensyn.service installed & active ✅"


###########################################################################
step "DONE ✅"
###########################################################################
echo -e "
${GREEN}✅ INSTALL DONE!
-----------------------------------------
➜ STATUS
  systemctl status gensyn

➜ LOGS
  journalctl -u gensyn -f
-----------------------------------------
${NC}
"
