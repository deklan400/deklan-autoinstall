#!/usr/bin/env bash
set -e

cd ~/rl-swarm || { echo "rl-swarm folder not found"; exit 1; }

echo "[*] Starting RL-Swarm..."
screen -S swarm -dm bash -c "
    docker compose run --rm --build -Pit swarm-cpu
"
echo "[+] RL-Swarm started in screen session: swarm"
