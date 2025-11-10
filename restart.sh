#!/usr/bin/env bash
set -e

echo "[*] Restart gensyn systemd service"
sudo systemctl restart gensyn
sleep 2
sudo systemctl status gensyn --no-pager
