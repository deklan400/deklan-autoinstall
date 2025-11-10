#!/usr/bin/env bash
set -e

###########################################################################
#   GENSYN RL-SWARM — UNINSTALL
#   by Deklan & GPT-5
###########################################################################

SERVICE_NAME="gensyn"

echo "
=====================================================
🧹  UNINSTALL GENSYN RL-SWARM
=====================================================
"

stop_and_disable() {
  systemctl stop "$SERVICE_NAME" || true
  systemctl disable "$SERVICE_NAME" || true
  rm -f "/etc/systemd/system/${SERVICE_NAME}.service"
  systemctl daemon-reload
}

echo "Stopping + removing systemd service..."
stop_and_disable

echo "Removing RL-Swarm folder..."
rm -rf /home/gensyn/rl_swarm || true

echo "Done ✅"
