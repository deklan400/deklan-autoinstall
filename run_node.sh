#!/usr/bin/env bash
set -euo pipefail

###########################################################################
#   GENSYN RL-SWARM STARTER v4 (CPU-only, Smart Mode)
#   by Deklan & GPT-5
###########################################################################

# ===== CONFIG =====
RL_DIR="/root/rl_swarm"
KEY_DIR="/root/deklan"

REQ=("swarm.pem" "userApiKey.json" "userData.json")


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
#   DETECT DOCKER COMPOSE
###########################################################################
if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
    COMPOSE_CMD="docker compose"
elif command -v docker-compose >/dev/null 2>&1; then
    COMPOSE_CMD="docker-compose"
else
    fail "docker compose not installed"
fi
info "Compose: $COMPOSE_CMD ✅"


###########################################################################
#   CHECK RL-SWARM DIR
###########################################################################
[[ -d "$RL_DIR" ]] || fail "RL-Swarm missing → $RL_DIR"


###########################################################################
#   CHECK IDENTITY
###########################################################################
for f in "${REQ[@]}"; do
    [[ -f "$KEY_DIR/$f" ]] || fail "Missing → $KEY_DIR/$f"
done
ok "Identity OK ✅"


###########################################################################
#   FIX SYMLINK → /root/rl_swarm/keys
###########################################################################
rm -rf "$RL_DIR/keys" 2>/dev/null || true
ln -s "$KEY_DIR" "$RL_DIR/keys"
ok "Symlink OK → $RL_DIR/keys → $KEY_DIR"


###########################################################################
#   CHECK DOCKER RUNNING
###########################################################################
docker info >/dev/null 2>&1 || fail "Docker not running"


###########################################################################
#   CLEAN STALE CONTAINERS
###########################################################################
info "Cleanup old containers…"
docker ps -aq | xargs -r docker rm -f >/dev/null 2>&1 || true


###########################################################################
#   PULL + BUILD SWARM-CPU
###########################################################################
info "Pull swarm-cpu…"
$COMPOSE_CMD -f "$RL_DIR/docker-compose.yaml" pull swarm-cpu || warn "pull failed"

info "Build swarm-cpu…"
$COMPOSE_CMD -f "$RL_DIR/docker-compose.yaml" build swarm-cpu || warn "build failed"

ok "Docker image OK ✅"


###########################################################################
#   RUN swarm-cpu (NO TTY)
###########################################################################
info "Starting swarm-cpu…"

docker rm -f swarm-cpu-run >/dev/null 2>&1 || true

exec $COMPOSE_CMD -f "$RL_DIR/docker-compose.yaml" run --rm -T \
    --name swarm-cpu-run \
    swarm-cpu
