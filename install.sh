#!/usr/bin/env bash
set -e

###########################################################################
#   GENSYN RL-SWARM INSTALLER v3.0
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

REQUIRED_FILES=("swarm.pem" "userData.json" "userApiKey.json")

msg()   { echo -e "${GREEN}✅ $1${NC}"; }
warn()  { echo -e "${YELLOW}⚠️  $1${NC}"; }
err()   { echo -e "${RED}❌ $1${NC}"; }
info()  { echo -e "${CYAN}$1${NC}"; }

echo -e "
${CYAN}=====================================================
🔥  GENSYN RL-SWARM CLEAN INSTALLER — v3.0
=====================================================${NC}
"

if [[ $EUID -ne 0 ]]; then
    err "Run as ROOT!"
    exit 1
fi

STEP=1
step() { echo -e "${YELLOW}[$STEP] $1${NC}"; STEP=$((STEP+1)); }

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
msg "System updated"


###########################################################################
step "Installing dependencies…"
###########################################################################
apt install -y curl git unzip build-essential pkg-config libssl-dev screen jq nano
msg "Deps OK"


###########################################################################
step "Install Docker (if missing)…"
###########################################################################
if ! command -v docker >/dev/null 2>&1; then
    info "Installing Docker…"
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg |
        gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo \
"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu \
$(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
> /etc/apt/sources.list.d/docker.list
    apt update
    apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    msg "Docker installed ✅"
else
    msg "Docker OK"
fi

systemctl enable --now docker || true


###########################################################################
step "Setup RL-Swarm repo…"
###########################################################################
if [[ ! -d "$RL_DIR" ]]; then
    git clone https://github.com/gensyn-ai/rl-swarm "$RL_DIR"
    msg "RL-Swarm cloned"
else
    warn "RL-Swarm exists → updating"
    pushd "$RL_DIR" >/dev/null
    git pull
    popd >/dev/null
    msg "RL-Swarm updated"
fi


###########################################################################
step "Link identity…"
###########################################################################
rm -rf "$RL_DIR/keys"
ln -s "$IDENTITY_DIR" "$RL_DIR/keys"
msg "Symlink OK → $RL_DIR/keys"


###########################################################################
step "Generate .env…"
###########################################################################
cat <<EOF > "$RL_DIR/.env"
GENSYN_KEY_DIR=$IDENTITY_DIR
PYTHONUNBUFFERED=1
EOF
msg ".env OK"


###########################################################################
step "Docker build/pull…"
###########################################################################
pushd "$RL_DIR" >/dev/null
docker compose pull || true
docker compose build swarm-cpu || true
popd >/dev/null
msg "Docker build OK"


###########################################################################
step "Install gensyn.service…"
###########################################################################
curl -s -o "$SERVICE_PATH" "${AUTO_REPO}gensyn.service"
chmod 644 "$SERVICE_PATH"

systemctl daemon-reload
systemctl enable --now "$SERVICE_NAME"
msg "gensyn.service installed & active ✅"


###########################################################################
step "Done!"
###########################################################################
echo -e "
${GREEN}✅ INSTALL DONE!
--------------------------------------
➜ STATUS
  systemctl status gensyn

➜ LOGS
  journalctl -u gensyn -f

${NC}
"
