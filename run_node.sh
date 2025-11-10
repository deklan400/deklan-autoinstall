#!/usr/bin/env bash
set -euo pipefail

###########################################################################
#   GENSYN RL-SWARM STARTER
#   by Deklan & GPT-5
###########################################################################

RL_DIR="/home/gensyn/rl_swarm"
LOG_DIR="$RL_DIR/logs"
MODEL="${MODEL_NAME:-}"
COMPOSE=$(command -v docker) # auto detect

# Force docker compose syntax
COMPOSE_CMD="docker compose"

# =====================================================
#   HELPERS
# =====================================================
fail() { echo -e "\e[31m❌ $1\e[0m"; exit 1; }
say()  { echo -e "\e[32m✅ $1\e[0m"; }
note() { echo -e "\e[36m$1\e[0m"; }
warn() { echo -e "\e[33m⚠ $1\e[0m"; }

# =====================================================
#   CHECK FOLDERS
# =====================================================
mkdir -p "$LOG_DIR"

cd "$RL_DIR" || fail "RL-Swarm folder not found → $RL_DIR"

note "
==================================================
 ⚡  GENSYN RL-SWARM — run_node.sh
==================================================
Time: $(date)
"

# =====================================================
#   CHECK docker
# =====================================================
if ! command -v docker >/dev/null 2>&1; then
    fail "docker not installed"
fi

# Try 'docker compose', fallback to plugin
if ! docker compose version >/dev/null 2>&1; then
    if ! docker-compose version >/dev/null 2>&1; then
        fail "docker compose not available"
    else
        COMPOSE_CMD="docker-compose"
    fi
fi


# =====================================================
#   GIT UPDATE
# =====================================================
if [[ -d ".git" ]]; then
    note "[*] Updating RL-Swarm repository…"
    git fetch --all >/dev/null 2>&1 || true
    git reset --hard origin/main  >/dev/null 2>&1 || true
    say "Repo updated ✅"
else
    warn "Not a git repo → skip update"
fi


# =====================================================
#   CLEAN DOCKER
# =====================================================
note "[*] Cleaning unused containers…"
docker ps -aq | xargs -r docker rm -f >/dev/null 2>&1 || true


# =====================================================
#   PULL IMAGES
# =====================================================
note "[*] Pulling latest images…"
$COMPOSE_CMD pull || warn "Failed pulling — continuing"


# =====================================================
#   BUILD
# =====================================================
note "[*] Building swarm-cpu…"
$COMPOSE_CMD build swarm-cpu || warn "Build failed — continuing"


# =====================================================
#   RUN NODE
# =====================================================
note "[*] Starting swarm-cpu container…"

EXTRA_MODEL_ARG=""
if [[ -n "$MODEL" ]]; then
    note "[*] Using MODEL: $MODEL"
    EXTRA_MODEL_ARG="--env MODEL_NAME=$MODEL"
fi

exec $COMPOSE_CMD run --rm -Pit $EXTRA_MODEL_ARG swarm-cpu
