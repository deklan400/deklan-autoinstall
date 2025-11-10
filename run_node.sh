#!/usr/bin/env bash
set -euo pipefail

###########################################################################
#   GENSYN RL-SWARM STARTER (STABLE v2)
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
#   PRE CHECKS
###########################################################################
mkdir -p "$LOG_DIR"

cd "$RL_DIR" || fail "RL-Swarm folder not found → $RL_DIR"


# ===== Load .env if exists =====
if [[ -f "$RL_DIR/.env" ]]; then
    export $(grep -v '^#' "$RL_DIR/.env" | xargs -d '\n')
fi

note "
==================================================
 ⚡  GENSYN RL-SWARM — run_node.sh
==================================================
Time  : $(date)
RL_DIR: $RL_DIR
KEYS  : $KEY_DIR
"


###########################################################################
#   KEYS CHECK
###########################################################################
if [[ ! -d "$KEY_DIR" ]]; then
    fail "Key folder missing → $KEY_DIR"
fi

# ensure symlink
if [[ ! -e "$RL_DIR/keys" ]]; then
    ln -s "$KEY_DIR" "$RL_DIR/keys"
    say "✅ keys symlink created"
else
    note "keys OK"
fi


###########################################################################
#   CHECK docker
###########################################################################
if ! command -v docker >/dev/null 2>&1; then
    fail "docker is not installed"
fi

if ! docker compose version >/dev/null 2>&1; then
    if command -v docker-compose >/dev/null 2>&1; then
        COMPOSE_CMD="docker-compose"
    else
        fail "docker compose not found"
    fi
fi

note "Using: $COMPOSE_CMD"


###########################################################################
#   GIT UPDATE (Auto / safe)
###########################################################################
if [[ -d ".git" ]]; then
    if [[ "${AUTO_UPDATE:-1}" == "1" ]]; then
        note "[*] Auto-updating RL-Swarm…"
        git fetch --all >/dev/null 2>&1 || true
        git reset --hard origin/main  >/dev/null 2>&1 || true
        say "✅ Repo updated"
    else
        warn "Skipping git update (AUTO_UPDATE=0)"
    fi
else
    warn "Not a git repo — skipping update"
fi


###########################################################################
#   CLEAN DEAD CONTAINERS
###########################################################################
note "[*] Cleaning unused containers…"
docker ps -aq | xargs -r docker rm -f >/dev/null 2>&1 || true


###########################################################################
#   PULL IMAGES
###########################################################################
note "[*] Pulling latest images…"
$COMPOSE_CMD pull || warn "pull failed"


###########################################################################
#   BUILD
###########################################################################
note "[*] Building swarm-cpu…"
$COMPOSE_CMD build swarm-cpu || warn "build failed"


###########################################################################
#   RUN NODE
###########################################################################
note "[*] Starting swarm-cpu…"

EXTRA_ARG=""
if [[ -n "$MODEL" ]]; then
    note "MODEL = $MODEL"
    EXTRA_ARG="--env MODEL_NAME=$MODEL"
fi

# Persistent container name for watchdog
exec $COMPOSE_CMD run --rm -P -it \
    --name swarm-cpu-run \
    $EXTRA_ARG \
    swarm-cpu
