#!/usr/bin/env bash
set -euo pipefail
#######################################################################################
# 🧹 DEKLAN-SUITE UNINSTALLER — v6  (RL-Swarm + Bot + Monitor)
# by Deklan × GPT-5 (Fusion Project)
#######################################################################################

SERVICES=("gensyn" "bot" "monitor.timer" "monitor.service")
RL_DIR="/root/rl-swarm"
BOT_DIR="/opt/deklan-node-bot"
KEY_DIR="/root/deklan"

# REMOVE_KEYS=1 → ikut hapus identity (swarm.pem, userApiKey.json, userData.json)
REMOVE_KEYS="${REMOVE_KEYS:-0}"

# ===== Colors =====
GREEN="\e[32m"; RED="\e[31m"; YELLOW="\e[33m"; CYAN="\e[36m"; NC="\e[0m"
msg(){ echo -e "${GREEN}✅ $1${NC}"; }; warn(){ echo -e "${YELLOW}⚠ $1${NC}"; }
fail(){ echo -e "${RED}❌ $1${NC}"; exit 1; }; info(){ echo -e "${CYAN}$1${NC}"; }

info "
=====================================================
 🧹  UNINSTALL — DEKLAN-SUITE (Node + Bot + Monitor)
=====================================================
"

[[ $EUID -ne 0 ]] && fail "Run as ROOT!"

# ───────────────────────────────────────────────
# 1. Stop & disable all services
# ───────────────────────────────────────────────
info "[1/6] Stopping and disabling services…"
for svc in "${SERVICES[@]}"; do
  systemctl stop "$svc" 2>/dev/null || true
  systemctl disable "$svc" 2>/dev/null || true
  rm -f "/etc/systemd/system/${svc}" "/etc/systemd/system/${svc}.service" 2>/dev/null || true
done
systemctl daemon-reload
msg "Services stopped and removed ✅"

# ───────────────────────────────────────────────
# 2. Remove RL-Swarm directory
# ───────────────────────────────────────────────
info "[2/6] Removing RL-Swarm directory…"
[[ -d "$RL_DIR" ]] && rm -rf "$RL_DIR" && msg "Removed → $RL_DIR" || warn "RL-Swarm folder not found"

# ───────────────────────────────────────────────
# 3. Remove Bot directory
# ───────────────────────────────────────────────
info "[3/6] Removing Bot directory…"
[[ -d "$BOT_DIR" ]] && rm -rf "$BOT_DIR" && msg "Removed → $BOT_DIR" || warn "Bot folder not found"

# ───────────────────────────────────────────────
# 4. Optional — Remove identity
# ───────────────────────────────────────────────
info "[4/6] Handling identity folder…"
if [[ "$REMOVE_KEYS" == "1" ]]; then
  [[ -d "$KEY_DIR" ]] && rm -rf "$KEY_DIR" && msg "Identity removed ✅" || warn "Identity not found"
else
  warn "Identity kept (set REMOVE_KEYS=1 to delete)"
fi

# ───────────────────────────────────────────────
# 5. Docker cleanup
# ───────────────────────────────────────────────
info "[5/6] Cleaning Docker objects…"
if command -v docker >/dev/null 2>&1; then
  docker ps -aq | xargs -r docker rm -f >/dev/null 2>&1 || true
  docker images | grep -E "swarm-cpu" | awk '{print $3}' | xargs -r docker rmi -f >/dev/null 2>&1 || true
  docker network prune -f >/dev/null 2>&1 || true
  msg "Docker cleaned ✅"
else
  warn "Docker not installed → skip"
fi

# ───────────────────────────────────────────────
# 6. Final check
# ───────────────────────────────────────────────
info "[6/6] Finalizing cleanup…"
rm -f "$RL_DIR/keys" 2>/dev/null || true
msg "Symlinks removed ✅"

echo -e "
${GREEN}=====================================================
 ✅ DEKLAN-SUITE UNINSTALL COMPLETE
=====================================================
✔ All services removed
✔ RL-Swarm & Bot folders deleted
✔ Docker cleaned
✔ Identity kept (unless REMOVE_KEYS=1)
=====================================================${NC}
"

