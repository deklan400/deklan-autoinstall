#!/usr/bin/env bash
set -euo pipefail

###########################################################################
#   GENSYN RL-SWARM — CLEAN UNINSTALL (SMART v3.4)
#   by Deklan & GPT-5
###########################################################################

SERVICE_NAME="gensyn"
RL_DIR="/root/rl_swarm"
KEY_DIR="/root/deklan"
BOT_DIR="/opt/deklan-node-bot"

REMOVE_KEYS="${REMOVE_KEYS:-0}"
FULL_WIPE="${FULL_WIPE:-0}"

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
 🧹  CLEAN UNINSTALL — GENSYN RL-SWARM
=====================================================${NC}
"


###########################################################################
# 0 — ROOT CHECK
###########################################################################
[[ $EUID -ne 0 ]] && err "Run as ROOT!" && exit 1


###########################################################################
# 1 — Stop & remove systemd
###########################################################################
info "[1/8] Removing node service…"

systemctl stop "$SERVICE_NAME" 2>/dev/null || true
systemctl disable "$SERVICE_NAME" 2>/dev/null || true
rm -f "/etc/systemd/system/${SERVICE_NAME}.service"
systemctl daemon-reload

msg "Node service removed ✅"


###########################################################################
# 2 — Remove RL-Swarm directory
###########################################################################
info "[2/8] Removing RL-Swarm folder…"

if [[ -d "$RL_DIR" ]]; then
    rm -rf "$RL_DIR"
    msg "Removed → $RL_DIR"
else
    warn "RL-Swarm not found → skip"
fi


###########################################################################
# 3 — Remove identity (OPTIONAL)
###########################################################################
info "[3/8] Identity folder → $KEY_DIR"

if [[ "$REMOVE_KEYS" == "1" ]]; then
    if [[ -d "$KEY_DIR" ]]; then
        rm -rf "$KEY_DIR"
        msg "Identity removed ✅"
    else
        warn "Identity missing → skip"
    fi
else
    warn "Identity retained (set REMOVE_KEYS=1 to remove)"
fi


###########################################################################
# 4 — Docker cleanup
###########################################################################
info "[4/8] Cleaning docker…"

if command -v docker >/dev/null 2>&1; then

    # stop & remove swarm containers
    docker ps -a --filter "name=swarm-cpu" -q \
        | xargs -r docker rm -f >/dev/null 2>&1 || true

    # remove images
    docker images | grep "swarm-cpu" | awk '{print $3}' \
        | xargs -r docker rmi -f >/dev/null 2>&1 || true

    # orphan networks
    docker network prune -f >/dev/null 2>&1 || true

    msg "Docker cleanup OK ✅"
else
    warn "Docker not installed → skip"
fi


###########################################################################
# 5 — Remove RL-Swarm symlink
###########################################################################
info "[5/8] Removing symlink…"

rm -f "$RL_DIR/keys" 2>/dev/null || true
msg "Symlink cleaned ✅"


###########################################################################
# 6 — Remove Telegram BOT (optional)
###########################################################################
info "[6/8] Checking bot…"

if [[ "$FULL_WIPE" == "1" ]]; then
    systemctl stop bot 2>/dev/null || true
    systemctl disable bot 2>/dev/null || true
    rm -f "/etc/systemd/system/bot.service"

    systemctl stop monitor.timer 2>/dev/null || true
    systemctl disable monitor.timer 2>/dev/null || true
    rm -f "/etc/systemd/system/monitor."*

    systemctl daemon-reload

    rm -rf "$BOT_DIR" 2>/dev/null || true
    rm -rf /tmp/.node_status.json 2>/dev/null || true

    msg "Bot + Monitor removed ✅"
else
    warn "Bot retained (set FULL_WIPE=1 to wipe bot)"
fi



###########################################################################
# 7 — OPTIONAL: remove .env
###########################################################################
info "[7/8] Cleaning .env…"

rm -f "$RL_DIR/.env" 2>/dev/null || true
msg ".env removed ✅"


###########################################################################
# 8 — FINAL
###########################################################################
echo -e "
${GREEN}=====================================================
 ✅ UNINSTALL COMPLETE
=====================================================

✔ Node service removed
✔ RL-Swarm folder removed
✔ Docker cleaned
✔ Symlink removed
✔ Keys kept (unless REMOVE_KEYS=1)
✔ Bot kept (unless FULL_WIPE=1)

=====================================================
${NC}
"
