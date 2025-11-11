#!/usr/bin/env bash
set -euo pipefail

###########################################################################
#   GENSYN RL-SWARM INSTALLER v4 (CPU-only, Smart 2-Mode)
#   by Deklan & GPT-5
###########################################################################

GREEN="\e[32m"; RED="\e[31m"; YELLOW="\e[33m"; CYAN="\e[36m"; NC="\e[0m"
msg()  { echo -e "${GREEN}✅ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠ $1${NC}"; }
err()  { echo -e "${RED}❌ $1${NC}"; }
info() { echo -e "${CYAN}$1${NC}"; }

echo -e "
${CYAN}=====================================================
🔥  GENSYN RL-SWARM INSTALLER — v4 (CPU-only)
=====================================================${NC}
"

[[ $EUID -ne 0 ]] && err "Run as ROOT!" && exit 1

# ---- Paths & Const ----
IDENTITY_DIR="/root/deklan"
RL_DIR="/root/rl-swarm"           # pakai nama repo resmi (hyphen)
SERVICE_NAME="gensyn"
SERVICE_PATH="/etc/systemd/system/${SERVICE_NAME}.service"
REPO_URL="https://github.com/gensyn-ai/rl-swarm"
REQUIRED_FILES=("swarm.pem" "userData.json" "userApiKey.json")

STEP=1; step() { echo -e "${YELLOW}[$STEP] $1${NC}"; STEP=$((STEP+1)); }

# ------------------------------------------------------------
step "Prepare identity folder…"
# ------------------------------------------------------------
mkdir -p "$IDENTITY_DIR"

# ------------------------------------------------------------
step "Detect mode (NEW vs EXISTING)…"
# ------------------------------------------------------------
missing_any=false
for f in "${REQUIRED_FILES[@]}"; do
  [[ -f "$IDENTITY_DIR/$f" ]] || missing_any=true
done

if $missing_any; then
  MODE="NEW"
  warn "Identity files incomplete → entering NEW USER mode (auto tunnel + login)"
else
  MODE="EXISTING"
  msg "All identity files found → EXISTING USER mode"
fi

# ------------------------------------------------------------
step "Update system & base deps…"
# ------------------------------------------------------------
apt update -y && apt upgrade -y
apt install -y curl git unzip build-essential pkg-config libssl-dev jq nano ca-certificates gnupg
msg "System & base deps OK"

# ------------------------------------------------------------
step "Install Docker & Compose (if missing)…"
# ------------------------------------------------------------
if ! command -v docker >/dev/null 2>&1; then
  info "Installing Docker…"
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg

  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu \
$(. /etc/os-release && echo "$VERSION_CODENAME") stable" > /etc/apt/sources.list.d/docker.list

  apt update -y
  apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  systemctl enable --now docker
  msg "Docker installed"
else
  msg "Docker already installed"
  systemctl enable --now docker || true
fi

# ------------------------------------------------------------
step "Clone / update RL-Swarm repo…"
# ------------------------------------------------------------
if [[ ! -d "$RL_DIR" ]]; then
  info "Cloning RL-Swarm → $RL_DIR"
  git clone "$REPO_URL" "$RL_DIR"
  msg "Cloned"
else
  info "Updating RL-Swarm"
  pushd "$RL_DIR" >/dev/null
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git fetch --all || true
    git reset --hard origin/main || true
    msg "Repo updated"
  else
    warn "RL_DIR exists but not a git repo → skip update"
  fi
  popd >/dev/null
fi

# ------------------------------------------------------------
step "Ensure user/keys symlink → /root/deklan"
# ------------------------------------------------------------
mkdir -p "$RL_DIR/user"
# bersihkan jika ada file lama 'keys' (bukan symlink)
if [[ -e "$RL_DIR/user/keys" && ! -L "$RL_DIR/user/keys" ]]; then
  rm -rf "$RL_DIR/user/keys"
fi
ln -sfn "$IDENTITY_DIR" "$RL_DIR/user/keys"
msg "Symlink OK → $RL_DIR/user/keys -> $IDENTITY_DIR"

# ------------------------------------------------------------
step "Create .env (optional, harmless if unused)…"
# ------------------------------------------------------------
if [[ ! -f "$RL_DIR/.env" ]]; then
  cat <<EOF > "$RL_DIR/.env"
PYTHONUNBUFFERED=1
EOF
  msg ".env created"
else
  msg ".env exists"
fi

# helper: detect compose command
if docker compose version >/dev/null 2>&1; then
  COMPOSE="docker compose"
else
  COMPOSE="docker-compose"
fi

# ------------------------------------------------------------
step "Pull/build docker images (CPU only)…"
# ------------------------------------------------------------
pushd "$RL_DIR" >/dev/null
set +e
$COMPOSE pull
$COMPOSE build swarm-cpu
set -e
popd >/dev/null
msg "Docker images ready"

# ------------------------------------------------------------
if [[ "$MODE" == "NEW" ]]; then
  step "NEW USER: install Node & localtunnel for WebUI link…"
  # Node.js for localtunnel
  if ! command -v node >/dev/null 2>&1; then
    curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
    apt install -y nodejs
  fi
  npm install -g localtunnel || true
  msg "Node & localtunnel ready"

  step "NEW USER: first run + expose WebUI via tunnel…"
  pushd "$RL_DIR" >/dev/null

  # start RL-Swarm (CPU) in background
  ($COMPOSE run --rm -Pit swarm-cpu) &

  # start tunnel & try to capture URL
  TUN_LOG="/tmp/lt_3000.log"
  (lt --port 3000 | tee "$TUN_LOG") &
  sleep 3

  TUN_URL="$(grep -m1 -Eo 'https?://[a-z0-9.-]+\.loca\.lt' "$TUN_LOG" || true)"
  echo ""
  if [[ -n "${TUN_URL}" ]]; then
    echo -e "${CYAN}Open this URL to login:${NC}  ${YELLOW}${TUN_URL}${NC}"
  else
    warn "Could not auto-detect tunnel URL. Run manually:  lt --port 3000"
  fi
  echo -e "${CYAN}After login, the node will create 3 files in:${NC} ${YELLOW}$IDENTITY_DIR${NC}"
  echo -e "  swarm.pem, userData.json, userApiKey.json"

  # wait for credentials to appear
  echo ""
  info "Waiting for credentials to be created…"
  until [[ -f "$IDENTITY_DIR/swarm.pem" && -f "$IDENTITY_DIR/userData.json" && -f "$IDENTITY_DIR/userApiKey.json" ]]; do
    sleep 3
  done
  msg "Credentials detected → proceeding to daemonize"
  popd >/dev/null
fi

# ------------------------------------------------------------
step "Install systemd service (CPU only)…"
# ------------------------------------------------------------
cat > "$SERVICE_PATH" <<EOF
[Unit]
Description=Gensyn RL-Swarm Node - CPU
After=network-online.target docker.service
Requires=docker.service

[Service]
Type=simple
WorkingDirectory=$RL_DIR
ExecStart=/usr/bin/$COMPOSE run --rm -Pit swarm-cpu
Restart=always
RestartSec=5
User=root
Environment="PYTHONUNBUFFERED=1"

[Install]
WantedBy=multi-user.target
EOF

chmod 0644 "$SERVICE_PATH"
systemctl daemon-reload
systemctl enable --now "$SERVICE_NAME"

msg "Service installed & started"

# ------------------------------------------------------------
step "✅ DONE"
# ------------------------------------------------------------
echo -e "
${GREEN}✅ INSTALL COMPLETE!
-----------------------------------------
➜ STATUS
  systemctl status ${SERVICE_NAME} --no-pager

➜ LOGS
  journalctl -u ${SERVICE_NAME} -f
-----------------------------------------
${NC}
"
