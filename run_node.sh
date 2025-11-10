#!/usr/bin/env bash
set -euo pipefail

###########################################################################
#   GENSYN RL-SWARM STARTER (FIXED)
#   by Deklan & GPT-5
###########################################################################

# ===== CONFIG =====
RL_DIR="/root/rl_swarm"
KEY_DIR="/root/deklan"
LOG_DIR="$RL_DIR/logs"
MODEL="${MODEL_NAME:-}"

COMPOSE_CMD="docker compose"

# ===== COLORS =====
GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
CYAN="\e[36m"
NC="\e[0m"

fail() { echo -e "${RED}❌ $1${NC}"; exit 1; }
say()  { echo -e "${GREEN}✅ $1${NC}"; }
note() { echo -e "${CYAN}$1${NC}"; }
warn() { echo -e "${YELLOW}⚠ $1${NC}"; }

###########################################################################
#   PREP CHECK
###########################################################################
mkdir -p "$LOG_DIR"

cd "$RL_DIR" || fail "RL-Swarm folder not found → $RL_DIR"

# load .env
if [[ -f "$RL_DIR/.env" ]]; then
    export $(grep -v '^#' "$RL_DIR/.env" | xargs -d '\n')
fi

note "
==================================================
 ⚡  GENSYN RL-SWARM — run_node.sh
==================================================
Time: $(date)
RL_DIR = $RL_DIR
"

###########################################################################
#   CHECK docker
###########################################################################
if ! command -v docker >/dev/null 2>&1; then
    fail "docker not installed"
fi

if ! docker compose version >/dev/null 2>&1; then
    if ! docker-compose version >/dev/null 2>&1; then
        fail "docker compose not found"
    else
        COMPOSE_CMD="docker-compose"
    fi
fi

###########################################################################
#   ASK OPTIONAL git update
###########################################################################
if [[ -d ".git" ]]; then
    read -p "Update RL-Swarm (git pull)? [Y/n] > " ans || true
    if [[ ! "$ans" =~ ^[Nn]$ ]]; then
        note "[*] Updating RL-Swarm…"
        git pull || warn "pull failed"
        say "Repo updated ✅"
    else
        warn "Skipping update"
    fi
else
    warn "Not a git repo → skip update"
fi

###########################################################################
#   PULL IMAGES
###########################################################################
note "[*] Pulling images…"
$COMPOSE_CMD pull || warn "Pull failed — continuing"

###########################################################################
#   BUILD
###########################################################################
note "[*] Building image…"
$COMPOSE_CMD build swarm-cpu || warn "Build failed — continuing"

###########################################################################
#   RUN NODE
###########################################################################
note "[*] Starting swarm-cpu…"

EXTRA_ARG=""
if [[ -n "$MODEL" ]]; then
    note "MODEL: $MODEL"
    EXTRA_ARG="--env MODEL_NAME=$MODEL"
fi

exec $COMPOSE_CMD run --rm -Pit $EXTRA_ARG swarm-cpu
