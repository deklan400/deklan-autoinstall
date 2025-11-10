#!/usr/bin/env bash
set -euo pipefail

RL_DIR="/home/gensyn/rl_swarm"
LOG_DIR="$RL_DIR/logs"
MODEL="${MODEL_NAME:-}"
COMPOSE="/usr/bin/docker compose"

# ---------------------------------------
# PREP
# ---------------------------------------
mkdir -p "$LOG_DIR"

cd "$RL_DIR" || {
    echo "❌ ERROR: rl-swarm folder not found at $RL_DIR"
    exit 1
}

echo "=================================================="
echo " ✅ Gensyn RL-Swarm — run_node.sh"
echo "=================================================="
echo "Time: $(date)"
echo ""

# ---------------------------------------
# GIT UPDATE
# ---------------------------------------
if [ -d ".git" ]; then
    echo "[*] Updating repository…"
    git fetch --all
    git reset --hard origin/main || true
else
    echo "⚠️ rl-swarm directory is not a git repo — skip update"
fi

# ---------------------------------------
# CLEANUP OLD CONTAINERS
# ---------------------------------------
echo "[*] Cleaning old containers…"
docker ps -aq | xargs -r docker rm -f >/dev/null 2>&1 || true

# ---------------------------------------
# PULL / BUILD
# ---------------------------------------
echo "[*] Pulling images…"
$COMPOSE pull || true

echo "[*] Building swarm-cpu…"
$COMPOSE build swarm-cpu || true

# ---------------------------------------
# RUN
# ---------------------------------------
echo "[*] Starting swarm-cpu Docker…"

# Optional: custom model
EXTRA_MODEL_ARG=""
if [[ -n "$MODEL" ]]; then
    echo "[*] Using model: $MODEL"
    EXTRA_MODEL_ARG="--env MODEL_NAME=$MODEL"
fi

# Logging via systemd journal
exec $COMPOSE run --rm -Pit swarm-cpu
