#!/usr/bin/env bash
set -euo pipefail

###########################################################################
#   GENSYN RL-SWARM — CLEAN UNINSTALL (STABLE v2)
#   by Deklan & GPT-5
###########################################################################

SERVICE_NAME="gensyn"
RL_DIR="/root/rl_swarm"
KEY_DIR="/root/deklan"

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
# 1 — Remove Systemd Service
###########################################################################
info "[1/5] Removing systemd service…"

systemctl stop "$SERVICE_NAME" 2>/dev/null || true
systemctl disable "$SERVICE_NAME" 2>/dev/null || true
rm -f "/etc/systemd/system/${SERVICE_NAME}.service"
systemctl daemon-reload

msg "Service removed ✅"


###########################################################################
# 2 — Remove RL-Swarm Code
###########################################################################
info "[2/5] Removing RL-Swarm directory…"

if [[ -d "$RL_DIR" ]]; then
    rm -rf "$RL_DIR"
    msg "Removed → $RL_DIR"
else
    warn "Directory not found → skip"
fi


###########################################################################
# 3 — Remove Keys (optional flag)
###########################################################################
REMOVE_KEYS="${REMOVE_KEYS:-0}"

info "[3/5] Keys folder → $KEY_DIR"

if [[ "$REMOVE_KEYS" == "1" ]]; then
    if [[ -d "$KEY_DIR" ]]; then
        rm -rf "$KEY_DIR"
        msg "Keys removed ✅"
    else
        warn "Keys folder missing → skip"
    fi
else
    warn "Keys retained (set REMOVE_KEYS=1 to auto-remove)"
fi


###########################################################################
# 4 — Docker Cleanup
###########################################################################
info "[4/5] Cleaning docker artifacts…"

# stop/remove containers named swarm-cpu
docker ps -a --filter "name=swarm-cpu" -q | xargs -r docker rm -f >/dev/null 2>&1 || true

# remove images with name swarm-cpu
docker images | grep "swarm-cpu" | awk '{print $3}' | xargs -r docker rmi -f >/dev/null 2>&1 || true

msg "Docker cleanup OK ✅"


###########################################################################
# 5 — Final Output
###########################################################################
echo -e "
${GREEN}=====================================================
 ✅ UNINSTALL COMPLETE
=====================================================

✔ Systemd service removed
✔ RL-Swarm code removed
✔ Keys kept (unless REMOVE_KEYS=1)
✔ Docker cleaned (swarm-cpu only)

=====================================================${NC}
"
