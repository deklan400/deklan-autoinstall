#!/usr/bin/env bash
set -e

cd /home/gensyn/rl_swarm || { echo "rl-swarm folder not found"; exit 1; }

echo "[*] Starting swarm-cpu docker..."
exec /usr/bin/docker compose run --rm -Pit swarm-cpu
