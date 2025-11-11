#!/usr/bin/env bash
set -euo pipefail

###########################################################################
#   GENSYN RL-SWARM — REINSTALL (v4 CPU-only)
#   by Deklan & GPT-5
###########################################################################

SERVICE_NAME="gensyn"
RL_DIR="/root/rl-swarm"
KEY_DIR="/root/deklan"
REPO_URL="https://github.com/gensyn-ai/rl-swarm"

REQ=("swarm.pem" "userData.json" "userApiKey.json")

GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
CYAN="\e[36m"
NC="\e[0m"

msg()  { echo -e "${GREEN}✅ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠ $1${NC}"; }
fail() { echo -e "${RED}❌ $1${NC}"; exit 1; }
info() { echo -e "${CYAN}$1${NC}"; }

info "
=====================================================
 🔁  REINSTALL RL-SWARM NODE — v4 CPU
=====================================================
"


###########################################################################
# ROOT CHECK
###########################################################################
[[ $EUID -ne 0 ]] && fail "Run as ROOT!"


###########################################################################
# STOP SERVICE
###########################################################################
info "[1/5] Stopping service…"
systemctl stop "$SERVICE_NAME" 2>/dev/null || true
systemctl disable "$SERVICE_NAME" 2>/dev/null || true


###########################################################################
# CHECK REPO
###########################################################################
info "[2/5] Fixing RL-Swarm repo…"

if [[ ! -d "$RL_DIR" ]]; then
    warn "Repo missing → cloning fresh"
    git clone "$REPO_URL" "$RL_DIR"
    msg "Repo cloned"

elif [[ ! -d "$RL_DIR/.git" ]]; then
    warn "$RL_DIR exists but NOT GIT → replacing"
    rm -rf "$RL_DIR"
    git clone "$REPO_URL" "$RL_DIR"
    msg "Repo replaced"

else
    pushd "$RL_DIR" >/dev/null
    git fetch --all >/dev/null 2>&1 || true
    git reset --hard origin/main >/dev/null 2>&1 || warn "git reset failed"
    popd >/dev/null
    msg "Repo synced ✅"
fi


###########################################################################
# VALIDATE IDENTITY
###########################################################################
info "[3/5] Checking identity…"

for f in "${REQ[@]}"; do
    [[ -f "$KEY_DIR/$f" ]] || fail "Missing → $KEY_DIR/$f"
done
msg "Identity OK ✅"


###########################################################################
# FIX SYMLINK
###########################################################################
rm -rf "$RL_DIR/keys" 2>/dev/null || true
ln -s "$KEY_DIR" "$RL_DIR/keys"
msg "Symlink OK → $RL_DIR/keys → $KEY_DIR"


###########################################################################
# UPDATE DOCKER CPU IMAGE
###########################################################################
info "[4/5] Updating docker image…"

if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
    COMPOSE="docker compose"
elif command -v docker-compose >/dev/null 2>&1; then
    COMPOSE="docker-compose"
else
    fail "docker compose not found"
fi

pushd "$RL_DIR" >/dev/null
$COMPOSE pull swarm-cpu || warn "pull failed"
$COMPOSE build swarm-cpu || warn "build failed"
popd >/dev/null

msg "Docker image updated ✅"


###########################################################################
# RESTART SERVICE
###########################################################################
info "[5/5] Restarting node service…"

systemctl daemon-reload
systemctl enable "$SERVICE_NAME" >/dev/null 2>&1 || true
systemctl restart "$SERVICE_NAME" || true
sleep 2

if systemctl is-active --quiet "$SERVICE_NAME"; then
    msg "NODE RUNNING ✅"
else
    fail "NODE FAILED → check logs:"
fi

echo ""
echo "➡ Logs:"
echo "   journalctl -u $SERVICE_NAME -f"
