#!/usr/bin/env bash
set -e

echo "[*] Restarting RL-Swarm service..."
sudo systemctl restart gensyn
sleep 2
sudo systemctl status gensyn --no-pager
