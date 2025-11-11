#!/usr/bin/env bash
set -euo pipefail

###########################################################################
#   GENSYN RL-SWARM STARTER v4 (CPU-only, Smart Mode)
#   by Deklan & GPT-5
###########################################################################

# ===== CONFIG =====
RL_DIR="/root/rl-swarm"
KEY_DIR="/root/deklan"
REPO_URL="https://github.com/gensyn-ai/rl-swarm"

COMPOSE_CMD=""

# ===== COLORS =====
GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
CYAN="\e[36m"
NC="\e[0m"

fail() { echo -e "${RED}❌ $1${NC}"; exit 1; }
ok()   { echo -e "${GREEN}✅ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠ $1${NC}"; }
info() { echo -e "${CYAN}$1${NC}"; }

info "
==================================================
 ⚡  GENSYN RL-SWARM — run_node.sh (CPU)
==================================================
Time     : $(date)
RL_DIR   : $RL_DIR
IDENTITY : $KEY_DIR
==================================================
"

###########################################################################
#   CHECK INTERNET (soft check)
###########################################################################
if ping -c1 -W1 github.com >/dev/null 2>&1; then
    ok "Internet OK"
else
    warn "Internet weak / unreachable → continue anyway"
fi


###########################################################################
#   ENSURE RL-SWARM EXISTS
###########################################################################
if [[ ! -d "$RL_DIR" ]]; then
    warn "RL-Swarm missing → cloning fresh"
    git clone "$REPO_URL" "$RL_DIR" || fail "Clone failed"
    ok "Repo cloned ✅"
fi

cd "$RL_DIR" || fail "RL-Swarm folder not found"


###########################################################################
#   DETECT COMPOSE
###########################################################################
if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
    COMPOSE_CMD="docker compose"
elif command -v docker-compose >/dev/null 2>&1; then
    COMPOSE_CMD="docker-compose"
else
    fail "Docker compose is not installed"
fi

info "Using → $COMPOSE_CMD"


###########################################################################
#   CHECK KEYS
###########################################################################
REQ=("swarm.pem" "userApiKey.json" "userData.json")

for f in "${REQ[@]}"; do
    [[ ! -f "$KEY_DIR/$f" ]] && fail "Missing → $KEY_DIR/$f"
done

ok "Identity OK ✅"


###########################################################################
#   FIX SYMLINK user/keys → /root/deklan
###########################################################################
mkdir -p "$RL_DIR/user"
rm -rf "$RL_DIR/user/keys" 2>/dev/null || true
ln -s "$KEY_DIR" "$RL_DIR/user/keys"
ok "Symlink: $RL_DIR/user/keys → $KEY_DIR"


###########################################################################
#   CHECK DOCKER
###########################################################################
if ! docker info >/dev/null 2>&1; then
    fail "Docker daemon NOT running"
fi


###########################################################################
#   CLEANUP OLD CONTAINERS
###########################################################################
info "Cleanup old containers…"
docker ps -aq | xargs -r docker rm -f >/dev/null 2>&1 || true


###########################################################################
#   PULL + BUILD CPU IMAGE
###########################################################################
info "Pull images…"
$COMPOSE_CMD pull || warn "pull failed"

info "Build swarm-cpu…"
$COMPOSE_CMD build swarm-cpu || warn "build failed"

ok "Docker image OK ✅"


###########################################################################
#   RUN swarm-cpu (NO TTY MODE)
###########################################################################
info "Starting swarm-cpu…"

# Remove any previous container
docker rm -f swarm-cpu-run >/dev/null 2>&1 || true

# IMPORTANT → for systemd: -T (no tty)
exec $COMPOSE_CMD run --rm -T \
    --name swarm-cpu-run \
    swarm-cpu
