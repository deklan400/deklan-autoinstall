#!/usr/bin/env bash
set -e

echo "[*] Restarting gensyn service..."
sudo systemctl restart gensyn

echo "[*] Waiting..."
sleep 2

sudo systemctl status gensyn --no-pager

echo ""
echo "[*] Tail logs (Ctrl+C to exit)"
journalctl -u gensyn -f
