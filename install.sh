#!/usr/bin/env bash
set -e

###########################################################################
#   GENSYN RL-SWARM AUTO INSTALLER (UPGRADED)
#   by Deklan & GPT-5
###########################################################################

# ========= COLORS =========
GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
CYAN="\e[36m"
NC="\e[0m"

# ========= SETTINGS ========
IDENTITY_DIR="/root/deklan"
REQUIRED_FILES=("swarm.pem" "userData.json" "userApiKey.json")
RL_HOME="/home/gensyn"
RL_DIR="$RL_HOME/rl_swarm"
KEYS_DIR="$RL_DIR/keys"
SERVICE_NAME="gensyn"
GITHUB_SERVICE_URL="https://raw.githubusercontent.com/deklan400/deklan-autoinstall/main/gensyn.service"

echo -e "
${CYAN}=====================================================
🔥  GENSYN RL-SWARM AUTO INSTALLER — UPGRADED
=====================================================${NC}
"

###########################################################################
#   HELPERS
###########################################################################
msg()   { echo -e "${GREEN}✅ $1${NC}"; }
warn()  { echo -e "${YELLOW}⚠️  $1${NC}"; }
err()   { echo -e "${RED}❌ $1${NC}"; }
info()  { echo -e "${CYAN}$1${NC}"; }

# -------- sudo check --------
if [[ $EUID -ne 0 ]]; then
    err "Run this script as ROOT."
    exit 1
fi


###########################################################################
#   CHECK IDENTITY FILES
###########################################################################
info "[1/10] Checking identity files…"
mkdir -p "$IDENTITY_DIR"

MISSING=0
for FILE in "${REQUIRED_FILES[@]}"; do
    if [[ ! -f "$IDENTITY_DIR/$FILE" ]]; then
        err "Missing: $IDENTITY_DIR/$FILE"
        MISSING=1
    else
        msg "Found → $FILE"
    fi
done

if [[ "$MISSING" -eq 1 ]]; then
    echo ""
    warn "Place your identity files here:"
    warn " → $IDENTITY_DIR"
    echo "
Required files:
 - swarm.pem
 - userData.json
 - userApiKey.json

Then re-run installer:
bash <(curl -s https://raw.githubusercontent.com/deklan400/deklan-autoinstall/main/install.sh)
"
    exit 1
fi


###########################################################################
#   UPDATE SYSTEM
###########################################################################
info "[2/10] Updating system…"
apt update -y && apt upgrade -y
msg "System updated"


###########################################################################
#   INSTALL BASE DEPENDENCIES
###########################################################################
info "[3/10] Installing dependencies…"
apt install -y curl git unzip build-essential pkg-config libssl-dev screen jq nano
msg "Dependencies OK"


###########################################################################
#   OPTIONAL — INSTALL NODE & YARN
###########################################################################
read -p "Install NodeJS + Yarn? (recommended) [Y/n] > " ans
if [[ "$ans" =~ ^[Nn]$ ]]; then
    warn "Skipping Node + Yarn"
else
    info "Installing NodeJS + Yarn…"
    curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
    apt install -y nodejs

    npm install -g yarn >/dev/null 2>&1 || true
    msg "NodeJS + Yarn installed ✅"
fi


###########################################################################
#   INSTALL DOCKER
###########################################################################
info "[4/10] Installing Docker…"

if ! command -v docker >/dev/null 2>&1; then
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
    msg "Docker already installed → skipping"
fi

systemctl enable --now docker >/dev/null 2>&1 || true


###########################################################################
#   CREATE gensyn USER + DIRECTORY
###########################################################################
info "[5/10] Preparing RL-Swarm folder…"

if ! id "gensyn" >/dev/null 2>&1; then
    useradd -m -s /bin/bash gensyn
fi

mkdir -p "$RL_HOME"
chown -R gensyn:gensyn "$RL_HOME"
msg "User + folder ready"


###########################################################################
#   CLONE / UPDATE RL-SWARM
###########################################################################
info "[6/10] Pulling RL-Swarm repo…"

if [[ ! -d "$RL_DIR" ]]; then
    sudo -u gensyn git clone https://github.com/gensyn-ai/rl-swarm "$RL_DIR"
    msg "Repo cloned"
else
    pushd "$RL_DIR" >/dev/null
    sudo -u gensyn git pull
    popd >/dev/null
    msg "Repo updated"
fi


###########################################################################
#   COPY IDENTITY FILES
###########################################################################
info "[7/10] Copying identity files…"

mkdir -p "$KEYS_DIR"

for FILE in "${REQUIRED_FILES[@]}"; do
    cp "$IDENTITY_DIR/$FILE" "$KEYS_DIR/$FILE"
done

chmod 600 "$KEYS_DIR/swarm.pem"
chown -R gensyn:gensyn "$KEYS_DIR"
msg "Identity OK → $KEYS_DIR"


###########################################################################
#   INSTALL SYSTEMD SERVICE
###########################################################################
info "[8/10] Installing systemd service…"

curl -s -o "/etc/systemd/system/${SERVICE_NAME}.service" "$GITHUB_SERVICE_URL"

systemctl daemon-reload
systemctl enable --now "$SERVICE_NAME"
msg "Systemd installed & started"


###########################################################################
#   VALIDATE SERVICE
###########################################################################
info "[9/10] Checking node…"
sleep 2

if systemctl is-active --quiet "$SERVICE_NAME"; then
    msg "Node is RUNNING ✅"
else
    err "Node is NOT running! Check logs:"
    echo "journalctl -u $SERVICE_NAME -f"
fi


###########################################################################
#   DONE
###########################################################################
echo -e "
${GREEN}=====================================================
 ✅ INSTALLATION COMPLETE
=====================================================${NC}

Service:   ${SERVICE_NAME}
Folder:    ${RL_DIR}

Check logs:
  journalctl -u ${SERVICE_NAME} -f

Restart node:
  systemctl restart ${SERVICE_NAME}

"
