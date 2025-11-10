#!/usr/bin/env bash
set -e

###########################################################################
#   GENSYN RL-SWARM CLEAN INSTALLER (FIXED)
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

REQUIRED_FILES=("swarm.pem" "userData.json" "userApiKey.json")

msg()   { echo -e "${GREEN}✅ $1${NC}"; }
warn()  { echo -e "${YELLOW}⚠️  $1${NC}"; }
err()   { echo -e "${RED}❌ $1${NC}"; }
info()  { echo -e "${CYAN}$1${NC}"; }

echo -e "
${CYAN}=====================================================
🔥  GENSYN RL-SWARM CLEAN INSTALLER
=====================================================${NC}
"

if [[ $EUID -ne 0 ]]; then
    err "Run as ROOT"
    exit 1
fi

###########################################################################
#   CHECK KEYS
###########################################################################
info "[1/8] Checking identity files…"
for FILE in "${REQUIRED_FILES[@]}"; do
    if [[ ! -f "$IDENTITY_DIR/$FILE" ]]; then
        err "Missing: $IDENTITY_DIR/$FILE"
        NEED=1
    else
        msg "Found → $FILE"
    fi
done

if [[ "$NEED" == 1 ]]; then
    err "Missing identity files — abort"
    exit 1
fi

###########################################################################
#   UPDATE SYSTEM
###########################################################################
info "[2/8] Updating system…"
apt update -y && apt upgrade -y
msg "System updated"

###########################################################################
#   INSTALL DEPENDENCIES
###########################################################################
info "[3/8] Installing deps…"
apt install -y curl git unzip build-essential pkg-config libssl-dev screen jq nano
msg "Dependencies OK"

###########################################################################
#   OPTIONAL NODE + YARN
###########################################################################
read -p "Install NodeJS+Yarn? [Y/n] > " ans
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
#   DOCKER INSTALL
###########################################################################
info "[4/8] Checking Docker…"
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
    msg "Docker OK — skip"
fi

systemctl enable --now docker >/dev/null 2>&1 || true

###########################################################################
#   CLONE RL-SWARM
###########################################################################
info "[5/8] Managing RL-Swarm…"

if [[ ! -d "$RL_DIR" ]]; then
    git clone https://github.com/gensyn-ai/rl-swarm "$RL_DIR"
    msg "Repo cloned ✅"
else
    warn "Folder exists → $RL_DIR"
    read -p "Update repo (git pull)? [Y/n] > " pull_ans
    if [[ ! "$pull_ans" =~ ^[Nn]$ ]]; then
        pushd "$RL_DIR" >/dev/null
        git pull
        popd >/dev/null
        msg "Repo updated ✅"
    else
        warn "Skip update"
    fi
fi

###########################################################################
#   PREPARE KEYS
###########################################################################
info "[6/8] Preparing keys…"
rm -rf "$RL_DIR/keys"
ln -s "$IDENTITY_DIR" "$RL_DIR/keys"
msg "Symlink created → $RL_DIR/keys ✅"

###########################################################################
#   CREATE .env
###########################################################################
info "[7/8] Creating .env…"

cat <<EOF > "$RL_DIR/.env"
GENSYN_KEY_DIR=$IDENTITY_DIR
PYTHONUNBUFFERED=1
EOF

msg ".env ready ✅"

###########################################################################
#   DONE
###########################################################################
echo -e "
${GREEN}=====================================================
 ✅ INSTALL DONE — NEXT STEP
=====================================================
1) Ensure service installed:
$ systemctl enable $SERVICE_NAME

2) Start node:
$ systemctl restart $SERVICE_NAME

3) View logs:
$ journalctl -u $SERVICE_NAME -f
${NC}
"
