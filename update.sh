#!/usr/bin/env bash
set -euo pipefail

###########################################################################
#   GENSYN RL-SWARM — UPDATE (v4 CPU-only)
#   by Deklan & GPT-5
###########################################################################

SERVICE_NAME="gensyn"
RL_DIR="/root/rl_swarm"
KEY_DIR="/root/deklan"
REPO_URL="https://github.com/gensyn-ai/rl-swarm"

GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
CYAN="\e[36m"
NC="\e[0m"

say()  { echo -e "${GREEN}✅ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠ $1${NC}"; }
fail() { echo -e "${RED}❌ $1${NC}"; exit 1; }
note() { echo -e "${CYAN}$1${NC}"; }


note "
=====================================================
 ♻  UPDATE RL-SWARM — v4 (CPU)
=====================================================
"


###########################################################################
# ROOT CHECK
###########################################################################
[[ $EUID -ne 0 ]] && fail "Run as ROOT!"


###########################################################################
# STOP SERVICE
###########################################################################
note "[1/5] Stopping service…"
systemctl stop "$SERVICE_NAME" >/dev/null 2>&1 || warn "Not running"


###########################################################################
# CHECK RL-SWARM REPO
###########################################################################
note "[2/5] Checking RL-Swarm repo…"

if [[ ! -d "$RL_DIR/.git" ]]; then
    warn "Repo missing → cloning fresh"
    rm -rf "$RL_DIR"
    git clone "$REPO_URL" "$RL_DIR"
    say "Repo cloned ✅"
else
    say "Repo exists ✅"
fi


###########################################################################
# UPDATE REPO
###########################################################################
note "[3/5] Pulling updates…"

pushd "$RL_DIR" >/dev/null
git fetch --all >/dev/null 2>&1 || true
git reset --hard origin/main >/dev/null 2>&1 || warn "git reset failed"
popd >/dev/null

say "Repo updated ✅"


###########################################################################
# CHECK IDENTITY + SYMLINK
###########################################################################
note "[4/5] Checking identity…"

REQ=("swarm.pem" "userApiKey.json" "userData.json")

for f in "${REQ[@]}"; do
    [[ -f "$KEY_DIR/$f" ]] || fail "Missing → $KEY_DIR/$f"
done
say "Identity OK ✅"

# Fix symlink → /root/rl_swarm/keys
rm -rf "$RL_DIR/keys" 2>/dev/null || true
ln -s "$KEY_DIR" "$RL_DIR/keys"
say "Symlink OK → $RL_DIR/keys → $KEY_DIR ✅"


###########################################################################
# BUILD CPU IMAGE (optional)
###########################################################################
note "[5/5] Update Docker image…"

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

say "Docker image updated ✅"


###########################################################################
# RESTART SERVICE
###########################################################################
note "Restarting service…"

systemctl daemon-reload
systemctl restart "$SERVICE_NAME"
sleep 2

if systemctl is-active --quiet "$SERVICE_NAME"; then
    say "Node running ✅"
else
    fail "Node NOT running ❌"
fi


###########################################################################
# DONE
###########################################################################
say "✅ UPDATE COMPLETE"

echo ""
echo "➡ Follow logs:"
echo "   journalctl -u $SERVICE_NAME -f"
