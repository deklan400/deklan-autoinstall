#!/usr/bin/env bash
set -euo pipefail

###########################################################################
#   GENSYN RL-SWARM INSTALLER v5 (CPU-only)
#   by Deklan & GPT-5
###########################################################################

GREEN="\e[32m"; RED="\e[31m"; YELLOW="\e[33m"; CYAN="\e[36m"; NC="\e[0m"
msg()  { echo -e "${GREEN}✅ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠ $1${NC}"; }
err()  { echo -e "${RED}❌ $1${NC}"; }
info() { echo -e "${CYAN}$1${NC}"; }

echo -e "
${CYAN}=====================================================
🔥  GENSYN RL-SWARM AUTO INSTALLER (CPU only)
=====================================================${NC}
"

[[ $EUID -ne 0 ]] && err "Run as ROOT!" && exit 1

# ---- Paths ----
IDENTITY_DIR="/root/deklan"
RL_DIR="/root/rl-swarm"      # ✅ FIX HERE
SERVICE="gensyn"
SERVICE_PATH="/etc/systemd/system/${SERVICE}.service"
REPO_URL="https://github.com/gensyn-ai/rl-swarm"
REQUIRED_FILES=("swarm.pem" "userApiKey.json" "userData.json")

step() { echo -e "${YELLOW}[$(printf %02d $1)] $2${NC}"; }

# ------------------------------------------------------------
step 1 "Check identity files"
# ------------------------------------------------------------
mkdir -p "$IDENTITY_DIR"

for f in "${REQUIRED_FILES[@]}"; do
  [[ -f "$IDENTITY_DIR/$f" ]] || {
    err "❌ Missing → $f"
    echo -e "Required files:\n$IDENTITY_DIR/\n"
    exit 1
  }
done
msg "Identity OK ✅"


# ------------------------------------------------------------
step 2 "Install deps"
# ------------------------------------------------------------
apt update -y
apt install -y curl git jq ca-certificates gnupg build-essential
msg "Base deps OK ✅"


# ------------------------------------------------------------
step 3 "Install Docker"
# ------------------------------------------------------------
if ! command -v docker >/dev/null 2>&1; then
  info "Installing Docker…"

  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg

  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
    > /etc/apt/sources.list.d/docker.list

  apt update -y
  apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  systemctl enable --now docker
  msg "Docker installed ✅"
else
  msg "Docker OK ✅"
  systemctl enable --now docker || true
fi


# ------------------------------------------------------------
step 4 "Clone / update RL-Swarm"
# ------------------------------------------------------------
if [[ ! -d "$RL_DIR" ]]; then
  git clone "$REPO_URL" "$RL_DIR"
  msg "RL-Swarm cloned → $RL_DIR"
else
  pushd "$RL_DIR" >/dev/null
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git fetch --all || true
    git reset --hard origin/main || true
    msg "Repo updated ✅"
  else
    warn "$RL_DIR exists but not a git repo → skipping update"
  fi
  popd >/dev/null
fi


# ------------------------------------------------------------
step 5 "Symlink keys → $IDENTITY_DIR"
# ------------------------------------------------------------
pushd "$RL_DIR" >/dev/null

rm -rf   keys         >/dev/null 2>&1 || true
ln -sfn "$IDENTITY_DIR" keys

popd >/dev/null
msg "keys → $IDENTITY_DIR ✅"


# ------------------------------------------------------------
step 6 "Pull / Build docker"
# ------------------------------------------------------------
pushd "$RL_DIR" >/dev/null

if docker compose version >/dev/null 2>&1; then
  COMPOSE="docker compose"
else
  COMPOSE="docker-compose"
fi

set +e
$COMPOSE pull
$COMPOSE build swarm-cpu
set -e

popd >/dev/null
msg "Docker images OK ✅"


# ------------------------------------------------------------
step 7 "Install gensyn.service"
# ------------------------------------------------------------
cat > "$SERVICE_PATH" <<EOF
[Unit]
Description=Gensyn RL-Swarm Node
After=network-online.target docker.service
Wants=network-online.target docker.service
Requires=docker.service

[Service]
Type=simple
WorkingDirectory=$RL_DIR

# Ensure symlink exists
ExecStartPre=/bin/bash -c 'rm -rf $RL_DIR/keys && ln -s $IDENTITY_DIR $RL_DIR/keys'

ExecStart=/usr/bin/$COMPOSE run --rm -Pit swarm-cpu
ExecStop=/usr/bin/$COMPOSE down

Restart=always
RestartSec=5
User=root

LimitNOFILE=65535
Environment="PYTHONUNBUFFERED=1"

StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

chmod 0644 "$SERVICE_PATH"
systemctl daemon-reload
systemctl enable --now "$SERVICE"

msg "Service installed & started ✅"


# ------------------------------------------------------------
echo -e "
${GREEN}✅ INSTALL COMPLETE!
────────────────────────────────────────
➜ STATUS
  systemctl status ${SERVICE} --no-pager

➜ LOGS
  journalctl -u ${SERVICE} -f
────────────────────────────────────────${NC}
"
