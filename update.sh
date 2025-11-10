#!/usr/bin/env bash
set -euo pipefail

###########################################################################
#   GENSYN RL-SWARM — CLEAN UPDATE (SMART v3.4)
#   by Deklan & GPT-5
###########################################################################

SERVICE_NAME="gensyn"
RL_DIR="/root/rl_swarm"
KEY_DIR="/root/deklan"
REPO_URL="https://github.com/gensyn-ai/rl-swarm"

# FLAGS:
#   REBUILD=auto / ask / 0
#   CLEAN=1    → docker prune
#   MODE=fast  → skip docker + skip rebuild
#   MODE=full  → force rebuild
#
# EXAMPLE:
#   CLEAN=1 REBUILD=auto bash update.sh
#   MODE=fast bash update.sh
#   MODE=full bash update.sh

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
♻  UPDATE RL-SWARM — SMART v3.4
=====================================================${NC}
"


###########################################################################
# 0 — ROOT CHECK
###########################################################################
[[ $EUID -ne 0 ]] && err "Run as ROOT!" && exit 1


###########################################################################
# 1 — STOP SERVICE
###########################################################################
info "[1/6] Stopping service..."
systemctl stop "$SERVICE_NAME" >/dev/null 2>&1 || warn "Service not running"


###########################################################################
# 2 — ENSURE REPO EXISTS
###########################################################################
info "[2/6] Checking RL-Swarm folder..."

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
info "[3/6] Updating RL-Swarm repo..."
pushd "$RL_DIR" >/dev/null

git fetch --all >/dev/null 2>&1 || true
git reset --hard origin/main >/dev/null 2>&1 || warn "Reset failed"
git pull >/dev/null 2>&1 || warn "git pull failed"

popd >/dev/null
msg "RL-Swarm updated ✅"


###########################################################################
# 4 — CHECK IDENTITY + SYMLINK
###########################################################################
info "[4/6] Checking identity..."

REQ=("swarm.pem" "userApiKey.json" "userData.json")
MISS=0

for f in "${REQ[@]}"; do
    [[ ! -f "$KEY_DIR/$f" ]] && warn "Missing → $KEY_DIR/$f" && MISS=1
done

[[ $MISS == 1 ]] && err "Identity incomplete → abort" && exit 1

# Symlink
rm -f "$RL_DIR/keys" 2>/dev/null || true
ln -s "$KEY_DIR" "$RL_DIR/keys"
msg "Identity OK ✅"


###########################################################################
# 5 — .env CHECK
###########################################################################
info "[5/6] Checking .env..."
if [[ ! -f "$RL_DIR/.env" ]]; then
    cat <<EOF > "$RL_DIR/.env"
GENSYN_KEY_DIR=$KEY_DIR
PYTHONUNBUFFERED=1
EOF
    msg ".env created ✅"
else
    msg ".env OK"
fi


###########################################################################
# 6 — OPTIONAL DOCKER UPDATE
###########################################################################
MODE="${MODE:-}"

if [[ "$MODE" == "fast" ]]; then
    warn "MODE=fast → Skipping docker build/pull"
else
    # detect compose
    if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
        COMPOSE="docker compose"
    elif command -v docker-compose >/dev/null 2>&1; then
        COMPOSE="docker-compose"
    else
        err "docker compose not found"
    fi

    msg "compose → $COMPOSE"

    # force rebuild
    [[ "$MODE" == "full" ]] && REBUILD="auto"

    REBUILD="${REBUILD:-ask}"

    do_rebuild() {
        info "[docker] Updating images..."
        pushd "$RL_DIR" >/dev/null

        $COMPOSE pull swarm-cpu || warn "pull failed"
        $COMPOSE build swarm-cpu || warn "build failed"

        if [[ "${CLEAN:-0}" == "1" ]]; then
            warn "Pruning docker..."
            docker system prune -af >/dev/null 2>&1 || true
        fi

        popd >/dev/null
        msg "Docker updated ✅"
    }

    if [[ "$REBUILD" == "auto" ]]; then
        do_rebuild
    elif [[ "$REBUILD" == "ask" ]]; then
        read -p "Rebuild Docker? [Y/n] > " ans || true
        [[ ! "$ans" =~ ^[Nn]$ ]] && do_rebuild || warn "Skip docker build"
    else
        warn "Skip docker rebuild"
    fi
fi


###########################################################################
# 7 — RESTART SERVICE
###########################################################################
info "[6/6] Restarting service..."
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
