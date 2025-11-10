#!/usr/bin/env bash
set -e

# change to rl-swarm dir (same as RL_DIR in install.sh)
cd /home/gensyn/rl_swarm || { echo "rl-swarm folder not found"; exit 1; }

# Run docker compose (exec so PID managed by systemd)
exec /usr/bin/docker compose run --rm -Pit swarm-cpu
