# ✅ Gensyn RL-Swarm — One-Command Auto Installer

Installer otomatis untuk menjalankan **Gensyn RL-Swarm Node** di VPS hanya dengan **1 perintah**.  

Installer ini otomatis melakukan:
✅ Validasi identity  
✅ Install dependencies  
✅ Install Docker  
✅ Clone repo RL-Swarm  
✅ Copy identity ke folder keys  
✅ Setup systemd service  
✅ Auto-start Node  
✅ Aman & bisa dipindah VPS kapan pun  

Cocok untuk **deploy masal / pindah VPS sangat cepat 🚀**

---

## 📌 Persiapan (WAJIB)

Sebelum menjalankan installer, siapkan **3 file identity** berikut:

| File | Fungsi |
|------|--------|
| `swarm.pem` | Private key |
| `userApiKey.json` | API credential |
| `userData.json` | Account data |

Upload ketiga file ke:

```
/root/deklan/
```

📌 Folder `/root/deklan/` dibuat otomatis.  
📌 Isi file **tidak diambil dari internet** → upload manual → lebih aman ✅  

Jika salah satu file tidak ada → installer berhenti & minta upload dulu.

---

## 🚀 Quick Install

Jalankan perintah berikut di VPS:

```bash
bash <(curl -s https://raw.githubusercontent.com/deklan400/deklan-autoinstall/main/install.sh)
```

Installer akan:
- Validasi identity
- Install dependencies
- Install Docker
- Clone RL-Swarm
- Copy keys
- Install systemd
- Start node otomatis

---

## ⚙️ Struktur Folder

```
/root/deklan/
│── swarm.pem
│── userApiKey.json
└── userData.json

/home/gensyn/rl_swarm/
│── keys/
│     ├── swarm.pem
│     ├── userApiKey.json
│     └── userData.json
└── (RL-Swarm source)
```

Installer akan menyalin identity otomatis ke:
```
/home/gensyn/rl_swarm/keys/
```

---

## ▶ Cek Status Node

```bash
systemctl status gensyn
```

Melihat log live:

```bash
journalctl -u gensyn -f
```

---

## 🔄 Restart Node

```bash
bash <(curl -s https://raw.githubusercontent.com/deklan400/deklan-autoinstall/main/restart.sh)
```

Atau:

```bash
systemctl restart gensyn
```

---

## 🔢 Informasi Service

| File | Lokasi |
|------|--------|
| Service | `/etc/systemd/system/gensyn.service` |
| Directory | `/home/gensyn/rl_swarm/` |
| Keys | `/home/gensyn/rl_swarm/keys/` |

---

## ⚙ Systemd Service (Auto-Start)

Service akan auto-restart jika:
- VPS restart
- Node crash
- Node stop mendadak

Manual stop:

```bash
systemctl stop gensyn
```

Disable permanent:

```bash
systemctl disable gensyn
```

---

## ✅ run_node.sh

Script dipanggil oleh service systemd & memastikan docker compose selalu dijalankan.

---

## 📦 Re-Install (Fast-Move VPS)

Cukup copy identity:

```
/root/deklan/
```

Kemudian jalankan:

```bash
bash <(curl -s https://raw.githubusercontent.com/deklan400/deklan-autoinstall/main/install.sh)
```

→ Node langsung jalan!  
Tidak perlu isi apapun lagi ✅  

---

## ❌ Uninstall

```bash
systemctl stop gensyn
systemctl disable gensyn
rm /etc/systemd/system/gensyn.service
rm -rf /home/gensyn/rl_swarm
```

---

## ✅ Output Contoh

```
[1/9] Checking identity files... ✅
[2/9] Updating system...
[3/9] Installing dependencies...
[4/9] Installing Docker...
[5/9] Cloning rl-swarm repo...
[6/9] Copying identity files...
[7/9] Installing systemd service...
[8/9] Starting RL-Swarm...
```

Lalu node otomatis berjalan 🎉

---

## ⚠ Catatan Keamanan

❗ Jangan upload `swarm.pem` ke GitHub / internet  
❗ Backup offline aman  
✅ Installer tidak mengirim ke server manapun  

---

## ❤️ Credit
Built by **Deklan**

END OF README
