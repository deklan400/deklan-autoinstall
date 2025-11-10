✅ Gensyn RL-Swarm — One-Command Auto Installer

Installer otomatis untuk menjalankan Gensyn RL-Swarm Node di VPS dengan 1 perintah.
Installer akan:
✅ Validasi identity
✅ Install dependencies
✅ Install Docker
✅ Clone repository RL-Swarm
✅ Copy identity ke folder keys
✅ Setup systemd service
✅ Auto-start node

Cocok untuk pindah VPS cepat atau deploy massal 🚀

📌 Persiapan (Wajib)

Sebelum menjalankan installer, siapkan 3 file identity berikut:

swarm.pem
userApiKey.json
userData.json


Upload ketiga file ke lokasi:

/root/deklan/


Folder /root/deklan otomatis dibuat oleh installer
tetapi file harus di-upload manual (demi keamanan)

Tanpa file ini, installer akan berhenti & minta kamu upload dulu ✅

🚀 Install Node (1 Command)

Jalankan perintah berikut:

bash <(curl -s https://raw.githubusercontent.com/deklan400/deklan-autoinstall/main/install.sh)


Script akan otomatis:
✔ Cek identity
✔ Install dependencies
✔ Install Docker
✔ Clone rl-swarm
✔ Copy identity
✔ Install systemd
✔ Start node

Jika berhasil → node berjalan otomatis ✅

✅ Cek Status Node

Status:

systemctl status gensyn


Log real-time:

journalctl -u gensyn -f

🔁 Restart Node

Script helper:

bash <(curl -s https://raw.githubusercontent.com/deklan400/deklan-autoinstall/main/restart.sh)


Manual:

systemctl restart gensyn

▶ Start / Stop Manual

Start:

systemctl start gensyn


Stop:

systemctl stop gensyn

📁 Lokasi Identity
File	Path
swarm.pem	/root/deklan/swarm.pem
userApiKey.json	/root/deklan/userApiKey.json
userData.json	/root/deklan/userData.json
(copy otomatis) →	/home/gensyn/rl_swarm/keys/

Jika ingin ganti identity → cukup upload ulang file ke /root/deklan/ lalu:

systemctl restart gensyn

🗂 Struktur Repo
deklan-autoinstall/
├── install.sh       → Installer utama
├── restart.sh       → Restart helper
├── run_node.sh      → Node launcher
└── gensyn.service   → systemd service config

🔎 Debug

Lihat log node:

journalctl -u gensyn -f


Cek Docker:

docker ps


Cek folder keys:

ls -l /home/gensyn/rl_swarm/keys/

♻ Update Node

Jika rl-swarm update:

cd /home/gensyn/rl_swarm
git pull
systemctl restart gensyn

❌ Uninstall Node
systemctl stop gensyn
systemctl disable gensyn
rm -f /etc/systemd/system/gensyn.service
rm -rf /home/gensyn/rl_swarm
rm -rf /root/deklan
systemctl daemon-reload

✅ Keunggulan

✔ 1-command installer
✔ Identity auto-copy
✔ Systemd auto-restart
✔ Bisa pindah VPS cepat
✔ Bersih & minimalis

Upload identity → run installer → node otomatis jalan ✅
Praktis buat deploy banyak node 🚀

⚙ Requirements

Ubuntu 20.04 / 22.04 / 24.04

RAM minimal 4GB (lebih besar lebih baik)

Disk minimal 30GB

Koneksi internet stabil

🔥 Next Improvements (Opsional)

Fitur yang bisa ditambahkan:
✅ Telegram alerts
✅ Auto-update checker
✅ Auto-UI tunnel
✅ Remote monitoring
✅ Multi-node manager

Tinggal bilang → bisa gua bantu setup 💪

✨ Credits

Auto-installer dibuat oleh: @deklan400
Based on: https://github.com/gensyn-ai/rl-swarm

✅ Kesimpulan

Installer ini memungkinkan Anda menjalankan Gensyn RL-Swarm node
dalam hitungan detik hanya dengan satu perintah.

Simple. Cepat. Aman 🔥
Cocok untuk deploy single node maupun multi-node.
