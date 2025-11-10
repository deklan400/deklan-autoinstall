#!/usr/bin/env bash
set -euo pipefail

###########################################################################
#   GENSYN RL-SWARM STARTER (SMART v3.4)
#   by Deklan & GPT-5
###########################################################################

# ===== CONFIG =====
RL_DIR="/root/rl_swarm"
KEY_DIR="/root/deklan"
MODEL="${MODEL_NAME:-}"
REPO_URL="https://github.com/gensyn-ai/rl-swarm"

COMPOSE_CMD=""


# ===== COLORS =====
GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
CYAN="\e[36m"
NC="\e[0m"

fail() { echo -e "${RED}❌ $1${NC}"; exit 1; }
say()  { echo -e "${GREEN}✅ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠ $1${NC}"; }
note() { echo -e "${CYAN}$1${NC}"; }


###########################################################################
#   BANNER
###########################################################################
note "
==================================================
 ⚡  GENSYN RL-SWARM — run_node.sh
==================================================
Time     : $(date)
RL_DIR   : $RL_DIR
IDENTITY : $KEY_DIR
==================================================
"


###########################################################################
#   INTERNET CHECK
###########################################################################
note "[*] Checking internet…"
if ! ping -c1 -W1 github.com >/dev/null 2>&1; then
    warn "Internet weak / unreachable → continue anyway"
else
    say "Internet OK"
fi


###########################################################################
#   RL-SWARM CHECK → auto clone
###########################################################################
if [[ ! -d "$RL_DIR" ]]; then
    warn "RL-Swarm missing → cloning fresh"
    git clone "$REPO_URL" "$RL_DIR" || fail "Clone failed"
    say "Repo cloned ✅"
fi

cd "$RL_DIR" || fail "RL-Swarm folder not found"


###########################################################################
#   docker compose DETECT
###########################################################################
if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
    COMPOSE_CMD="docker compose"
elif command -v docker-compose >/dev/null 2>&1; then
    COMPOSE_CMD="docker-compose"
else
    fail "docker compose not found"
fi

note "Using → $COMPOSE_CMD"


###########################################################################
#   AUTO-UPDATE REPO
###########################################################################
if [[ -d ".git" ]]; then
    if [[ "${AUTO_UPDATE:-1}" == "1" ]]; then
        note "[*] Auto-updating RL-Swarm…"
        git fetch --all >/dev/null 2>&1 || true
        git reset --hard origin/main >/dev/null 2>&1 || true
        say "Repo updated ✅"
    else
        warn "AUTO_UPDATE=0 → Skip"
    fi
else
    warn "Not a git repo → skip update"
fi


###########################################################################
#   KEY CHECK
###########################################################################
REQ=("swarm.pem" "userApiKey.json" "userData.json")

for f in "${REQ[@]}"; do
    [[ ! -f "$KEY_DIR/$f" ]] && fail "Missing identity → $KEY_DIR/$f"
done
say "Identity OK ✅"


###########################################################################
#   Symlink ensure
###########################################################################
if [[ -L "$RL_DIR/keys" ]] || [[ -e "$RL_DIR/keys" ]]; then
    rm -rf "$RL_DIR/keys"
fi

ln -s "$KEY_DIR" "$RL_DIR/keys"
say "Symlink created ✅"


###########################################################################
#   .env CHECK
###########################################################################
if [[ ! -f "$RL_DIR/.env" ]]; then
cat <<EOF > "$RL_DIR/.env"
GENSYN_KEY_DIR=$KEY_DIR
PYTHONUNBUFFERED=1
EOF
    say ".env created ✅"
else
    note ".env exists"
fi


###########################################################################
#   docker alive?
###########################################################################
if ! docker info >/dev/null 2>&1; then
    fail "Docker daemon NOT running"
fi


###########################################################################
#   CLEAN ZOMBIE
###########################################################################
note "[*] Cleanup dead containers…"
docker ps -aq | xargs -r docker rm -f >/dev/null 2>&1 || true


###########################################################################
#   PULL + BUILD
###########################################################################
note "[*] Pulling images…"
$COMPOSE_CMD pull || warn "pull failed"

note "[*] Building image…"
$COMPOSE_CMD build swarm-cpu || warn "build failed"


###########################################################################
#   RUN
###########################################################################
note "[*] Starting swarm-cpu…"

EXTRA=""
[[ -n "$MODEL" ]] && EXTRA="--env MODEL_NAME=$MODEL"

docker rm -f swarm-cpu-run >/dev/null 2>&1 || true

exec $COMPOSE_CMD run --rm -P -it \
    --name swarm-cpu-run \
    $EXTRA \
    swarm-cpu
