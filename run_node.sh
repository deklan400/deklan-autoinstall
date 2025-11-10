#!/usr/bin/env bash
set -e

cd ~/rl-swarm || { echo "rl-swarm folder not found"; exit 1; }

exec /usr/bin/docker compose run --rm -Pit swarm-cpu
