#!/usr/bin/env bash
set -euo pipefail

###########################################################################
#   GENSYN RL-SWARM — CLEAN UPDATE (SMART v3)
#   by Deklan & GPT-5
###########################################################################

SERVICE_NAME="gensyn"
RL_DIR="/root/rl_swarm"
REPO_URL="https://github.com/gensyn-ai/rl-swarm"

# flags:
#   REBUILD=auto / ask / 0
#   CLEAN=1 → remove old docker cache
#
# Example:
#   REBUILD=auto CLEAN=1 bash update.sh

GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
CYAN="\e[36m"
NC="\e[0m"

msg()  { echo -e "${GREEN}✅ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠ $1${NC}"; }
err()  { echo -e "${RED}❌ $1${NC}"; }
info() { echo -e "${CYAN}$1${NC}"; }

echo -e "
${CYAN}=====================================================
♻  UPDATE RL-SWARM — SMART v3
=====================================================${NC}
"

###########################################################################
# 0 — ROOT CHECK
###########################################################################
if [[ $EUID -ne 0 ]]; then
    err "Run as ROOT!"
    exit 1
fi


###########################################################################
# 1 — STOP SERVICE
###########################################################################
info "[1/5] Stopping service..."
systemctl stop "$SERVICE_NAME" >/dev/null 2>&1 || warn "Service not running"


###########################################################################
# 2 — VALIDATE REPO
###########################################################################
info "[2/5] Checking RL-Swarm folder..."

if [[ ! -d "$RL_DIR/.git" ]]; then
    warn "Repo broken/missing → Re-cloning..."
    rm -rf "$RL_DIR"
    git clone "$REPO_URL" "$RL_DIR"
    msg "Repo cloned ✅"
else
    msg "Repo OK"
fi


###########################################################################
# 3 — UPDATE REPO
###########################################################################
info "[3/5] Updating RL-Swarm repo..."

pushd "$RL_DIR" >/dev/null

# Safe update (always CLEAN)
git fetch --all >/dev/null 2>&1 || true
git reset --hard origin/main >/dev/null 2>&1 || warn "Hard reset failed"
git pull || warn "git pull failed — continuing"

popd >/dev/null

msg "RL-Swarm updated ✅"


###########################################################################
# 4 — DOCKER BUILD
###########################################################################
# Detect compose
if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
    COMPOSE="docker compose"
elif command -v docker-compose >/dev/null 2>&1; then
    COMPOSE="docker-compose"
else
    err "docker compose not found"
    exit 1
fi

msg "compose → $COMPOSE"

REBUILD="${REBUILD:-ask}"

do_rebuild() {
    info "[4/5] Updating docker..."
    pushd "$RL_DIR" >/dev/null

    $COMPOSE pull swarm-cpu || warn "pull failed"
    $COMPOSE build swarm-cpu || warn "build failed"

    if [[ "${CLEAN:-0}" == "1" ]]; then
        warn "Cleaning docker cache..."
        docker system prune -af >/dev/null 2>&1 || true
    fi

    popd >/dev/null
    msg "Docker updated ✅"
}

if [[ "$REBUILD" == "auto" ]]; then
    do_rebuild
elif [[ "$REBUILD" == "ask" ]]; then
    read -p "Rebuild Docker images? [Y/n] > " ans || true
    [[ ! "$ans" =~ ^[Nn]$ ]] && do_rebuild || warn "Skipping rebuild"
else
    warn "Skipping rebuild"
fi


###########################################################################
# 5 — RESTART SERVICE
###########################################################################
info "[5/5] Restarting service..."
systemctl daemon-reload
systemctl restart "$SERVICE_NAME" || true
sleep 2

if systemctl is-active --quiet "$SERVICE_NAME"; then
    msg "Node running ✅"
else
    err "Node NOT running ❌"
    echo ""
    echo "Last logs:"
    journalctl -u "$SERVICE_NAME" -n 40 --no-pager
    exit 1
fi

msg "✅ UPDATE COMPLETE"
echo ""
echo "➡ Follow logs:"
echo "   journalctl -u $SERVICE_NAME -f"
