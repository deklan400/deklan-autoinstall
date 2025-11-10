#!/usr/bin/env bash
set -euo pipefail

###########################################################################
#   GENSYN RL-SWARM — FULL UNINSTALL (UPGRADED)
#   by Deklan & GPT-5
###########################################################################

SERVICE_NAME="gensyn"
RL_HOME="/home/gensyn"
RL_DIR="$RL_HOME/rl_swarm"
KEYS_DIR="$RL_DIR/keys"

GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
CYAN="\e[36m"
NC="\e[0m"

msg()  { echo -e "${GREEN}✅ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠️ $1${NC}"; }
err()  { echo -e "${RED}❌ $1${NC}"; }
info() { echo -e "${CYAN}$1${NC}"; }

echo -e "
${CYAN}=====================================================
🧹  UNINSTALL GENSYN RL-SWARM
=====================================================${NC}
"

if [[ $EUID -ne 0 ]]; then
    err "Run as ROOT!"
    exit 1
fi


###########################################################################
#   STOP & REMOVE SERVICE
###########################################################################
info "[1/5] Removing systemd service…"

systemctl stop "$SERVICE_NAME" 2>/dev/null || true
systemctl disable "$SERVICE_NAME" 2>/dev/null || true
rm -f "/etc/systemd/system/${SERVICE_NAME}.service"
systemctl daemon-reload

msg "Service removed ✅"


###########################################################################
#   STOP + CLEAN DOCKER CONTAINERS
###########################################################################
info "[2/5] Cleaning Docker containers…"

docker ps -aq | xargs -r docker rm -f >/dev/null 2>&1 || true
docker system prune -af >/dev/null 2>&1 || true
msg "Docker cleanup OK ✅"


###########################################################################
#   REMOVE RL-SWARM DIRECTORY
###########################################################################
info "[3/5] Removing RL-Swarm directory…"

if [[ -d "$RL_DIR" ]]; then
    rm -rf "$RL_DIR"
    msg "Removed → $RL_DIR"
else
    warn "RL dir missing → skip"
fi


###########################################################################
#   ASK REMOVE USER
###########################################################################
info "[4/5] Optional: delete user gensyn"

read -p "Delete user 'gensyn'? [y/N] > " ans
if [[ "$ans" =~ ^[Yy]$ ]]; then
    systemctl stop "$SERVICE_NAME" 2>/dev/null || true
    pkill -u gensyn >/dev/null 2>&1 || true
    userdel -r gensyn 2>/dev/null || warn "Could not remove user"
    msg "User 'gensyn' deleted ✅"
else
    msg "User kept ✅"
fi


###########################################################################
#   DONE
###########################################################################
echo -e "
${GREEN}✅ UNINSTALL COMPLETE!
=====================================================${NC}
"
