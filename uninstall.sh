#!/usr/bin/env bash
set -euo pipefail

###########################################################################
#   GENSYN RL-SWARM — CLEAN UNINSTALL
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
🧹  CLEAN UNINSTALL GENSYN RL-SWARM
=====================================================${NC}
"

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
# 2 — Clean RL-SWARM Directory
###########################################################################
info "[2/5] Removing RL-Swarm code…"

if [[ -d "$RL_DIR" ]]; then
    rm -rf "$RL_DIR"
    msg "Removed → $RL_DIR"
else
    warn "RL-Swarm folder missing → skip"
fi

###########################################################################
# 3 — Keys folder (optional)
###########################################################################
info "[3/5] Keys folder → $KEY_DIR"
read -p "Remove keys folder? [y/N] > " ans || true
if [[ "$ans" =~ ^[Yy]$ ]]; then
    rm -rf "$KEY_DIR"
    msg "Keys removed ✅"
else
    warn "Keys retained ✅"
fi

###########################################################################
# 4 — Docker cleanup (NON-DESTRUCTIVE)
###########################################################################
info "[4/5] Cleaning docker (swarm-cpu only)…"

docker ps -a --filter "name=swarm-cpu" -q | xargs -r docker rm -f >/dev/null 2>&1 || true
docker images | grep swarm-cpu | awk '{print $3}' | xargs -r docker rmi -f >/dev/null 2>&1 || true

msg "Docker partial cleanup complete ✅"

###########################################################################
# 5 — Final
###########################################################################
echo -e "
${GREEN}✅ UNINSTALL COMPLETE
=====================================================
Remaining items:
✔ Keys kept (unless deleted)
✔ Docker untouched (except swarm-cpu)
=====================================================
${NC}
"
