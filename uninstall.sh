#!/usr/bin/env bash
set -euo pipefail

###########################################################################
#   GENSYN RL-SWARM — UNINSTALL (v4 CPU-only)
#   by Deklan & GPT-5
###########################################################################

SERVICE_NAME="gensyn"
RL_DIR="/root/rl-swarm"
KEY_DIR="/root/deklan"

REMOVE_KEYS="${REMOVE_KEYS:-0}"

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
 🧹  UNINSTALL — GENSYN RL-SWARM (CPU-only)
=====================================================
"


###########################################################################
# ROOT CHECK
###########################################################################
[[ $EUID -ne 0 ]] && fail "Run as ROOT!"


###########################################################################
# STOP + REMOVE systemd
###########################################################################
info "[1/5] Removing node service…"

systemctl stop "$SERVICE_NAME" 2>/dev/null || true
systemctl disable "$SERVICE_NAME" 2>/dev/null || true

rm -f "/etc/systemd/system/${SERVICE_NAME}.service"
systemctl daemon-reload

msg "Node service removed ✅"


###########################################################################
# REMOVE RL-SWARM
###########################################################################
info "[2/5] Removing RL-Swarm folder…"

if [[ -d "$RL_DIR" ]]; then
    rm -rf "$RL_DIR"
    msg "Removed → $RL_DIR"
else
    warn "RL-Swarm not found → skip"
fi


###########################################################################
# REMOVE identity (optional)
###########################################################################
info "[3/5] Identity folder → $KEY_DIR"

if [[ "$REMOVE_KEYS" == "1" ]]; then
    if [[ -d "$KEY_DIR" ]]; then
        rm -rf "$KEY_DIR"
        msg "Identity removed ✅"
    else
        warn "Identity folder missing → skip"
    fi
else
    warn "Identity retained (set REMOVE_KEYS=1 to delete)"
fi


###########################################################################
# docker cleanup
###########################################################################
info "[4/5] Cleaning docker objects…"

if command -v docker >/dev/null 2>&1; then

    # stop & remove swarm containers
    docker ps -a --filter "name=swarm-cpu" -q \
      | xargs -r docker rm -f >/dev/null 2>&1 || true

    # remove CPU swarm images
    docker images | grep "swarm-cpu" | awk '{print $3}' \
      | xargs -r docker rmi -f >/dev/null 2>&1 || true

    docker network prune -f >/dev/null 2>&1 || true
    msg "Docker cleaned ✅"
else
    warn "Docker not installed → skip"
fi


###########################################################################
# REMOVE SYMLINK
###########################################################################
info "[5/5] Removing symlink…"

rm -f "$RL_DIR/user/keys" 2>/dev/null || true
msg "Symlink cleaned ✅"


###########################################################################
# DONE
###########################################################################
echo -e "
${GREEN}=====================================================
 ✅ UNINSTALL COMPLETE
=====================================================

✔ Node service removed
✔ RL-Swarm removed
✔ Docker cleaned
✔ Symlink cleaned
✔ Keys kept (unless REMOVE_KEYS=1)

=====================================================
${NC}
"
