#!/usr/bin/env bash
set -euo pipefail

###########################################################################
#   GENSYN RL-SWARM — CLEAN UNINSTALL (SMART v3)
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
if [[ $EUID -ne 0 ]]; then
    err "Run as ROOT!"
    exit 1
fi


###########################################################################
# 1 — Stop + remove systemd service
###########################################################################
info "[1/7] Removing Node systemd service…"

systemctl stop "$SERVICE_NAME" 2>/dev/null || true
systemctl disable "$SERVICE_NAME" 2>/dev/null || true
rm -f "/etc/systemd/system/${SERVICE_NAME}.service"
systemctl daemon-reload

msg "Node service removed ✅"


###########################################################################
# 2 — Remove RL-Swarm directory
###########################################################################
info "[2/7] Removing RL-Swarm directory…"

if [[ -d "$RL_DIR" ]]; then
    rm -rf "$RL_DIR"
    msg "Removed → $RL_DIR"
else
    warn "RL-Swarm not found → skip"
fi


###########################################################################
# 3 — Remove identity keys (OPTIONAL)
###########################################################################
info "[3/7] Identity folder → $KEY_DIR"

if [[ "$REMOVE_KEYS" == "1" ]]; then
    if [[ -d "$KEY_DIR" ]]; then
        rm -rf "$KEY_DIR"
        msg "Keys removed ✅"
    else
        warn "Keys missing → skip"
    fi
else
    warn "Keys retained (set REMOVE_KEYS=1 to auto-remove)"
fi


###########################################################################
# 4 — Docker cleanup (containers + images)
###########################################################################
info "[4/7] Cleaning docker artifacts…"

docker ps -a --filter "name=swarm-cpu" -q \
    | xargs -r docker rm -f >/dev/null 2>&1 || true

docker images \
    | grep "swarm-cpu" | awk '{print $3}' \
    | xargs -r docker rmi -f >/dev/null 2>&1 || true

msg "Docker cleanup OK ✅"


###########################################################################
# 5 — OPTION: Remove Deklan Telegram Bot
###########################################################################
info "[5/7] Checking bot…"

if [[ "$FULL_WIPE" == "1" ]]; then
    systemctl stop bot 2>/dev/null || true
    systemctl disable bot 2>/dev/null || true
    rm -f "/etc/systemd/system/bot.service"

    systemctl stop monitor.timer 2>/dev/null || true
    systemctl disable monitor.timer 2>/dev/null || true
    rm -f "/etc/systemd/system/monitor."*

    systemctl daemon-reload

    rm -rf "$BOT_DIR"
    msg "Bot + monitor removed ✅"
else
    warn "Bot retained (set FULL_WIPE=1 to wipe bot)"
fi


###########################################################################
# 6 — Remove RL-Swarm symlink
###########################################################################
info "[6/7] Cleaning symlink…"
rm -f "$RL_DIR/keys" 2>/dev/null || true
msg "Symlink OK ✅"


###########################################################################
# 7 — Final Result
###########################################################################
echo -e "
${GREEN}=====================================================
 ✅ UNINSTALL COMPLETE
=====================================================

✔ Node service removed
✔ RL-Swarm directory removed
✔ Docker cleaned
✔ Keys kept (unless REMOVE_KEYS=1)
✔ Bot kept (unless FULL_WIPE=1)

=====================================================
${NC}
"

