<!-- DARK MODE STYLED README -->

<div align="center">

# 🌙🚀 GENSYN RL-SWARM  
### ⚡ ONE-COMMAND AUTO INSTALLER

> **Deploy Gensyn Node dalam 10 detik — aman, simple, otomatis.**  

<img src="https://img.shields.io/badge/Gensyn-RL--Swarm-0a84ff?style=for-the-badge"/>
<img src="https://img.shields.io/badge/Auto_Installer-00d18a?style=for-the-badge"/>
<img src="https://img.shields.io/badge/Systemd-AutoStart-fd8a09?style=for-the-badge"/>
<img src="https://img.shields.io/badge/Local_Identity-Safe-critical?style=for-the-badge"/>
<img src="https://img.shields.io/badge/Copy_And_Run-1_Step-lightgrey?style=for-the-badge"/>

</div>

---

<p align="center">
<img width="85%" src="https://raw.githubusercontent.com/deklan400/deklan-autoinstall/main/assets/dark-preview.png" />
</p>

> ✅ Jika preview belum ada → nanti tinggal upload screenshotnya ke folder `/assets/`

---

## ✅ Fitur Utama

✔ Validasi identity  
✔ Install dependencies  
✔ Install Docker  
✔ Clone RL-Swarm  
✔ Copy identity → `/keys`  
✔ Setup systemd service  
✔ Auto-start & auto-restart  
✔ Cocok deploy massal / pindah VPS  

---

## 📁 Persiapan Identity (WAJIB)

Tambahkan **3 file** ini:

| File | Fungsi |
|------|--------|
| `swarm.pem` | Private key |
| `userApiKey.json` | API Credential |
| `userData.json` | Account Data |

📌 Upload ke:

```
/root/deklan/
```

Jika ada yg kurang → installer berhenti otomatis ⚠️  

---

## 🚀 Quick Install

```
bash <(curl -s https://raw.githubusercontent.com/deklan400/deklan-autoinstall/main/install.sh)
```

> ✅ Node auto hidup  
> ✅ Tidak perlu config manual  

---

## 📂 Struktur Folder

```
/root/deklan/
│── swarm.pem
│── userApiKey.json
└── userData.json

/home/gensyn/rl_swarm/
│── keys/
│   ├── swarm.pem
│   ├── userApiKey.json
│   └── userData.json
└── source ...
```

Identity otomatis →  
```
/home/gensyn/rl_swarm/keys/
```

---

## 📊 Cek Node

```
systemctl status gensyn
```

Log realtime:
```
journalctl -u gensyn -f
```

---

## 🔁 Restart Node

```
systemctl restart gensyn
```

Atau:
```
bash <(curl -s https://raw.githubusercontent.com/deklan400/deklan-autoinstall/main/restart.sh)
```

---

## 📌 Lokasi Penting

| Resource | Path |
|----------|------|
| Service file | `/etc/systemd/system/gensyn.service` |
| Repo folder  | `/home/gensyn/rl_swarm/` |
| Keys folder  | `/home/gensyn/rl_swarm/keys/` |

---

## 🔄 Auto-Restart

Node auto restart ketika:
✅ VPS reboot  
✅ Node crash  
✅ Node mati mendadak  

Stop:
```
systemctl stop gensyn
```

Disable:
```
systemctl disable gensyn
```

---

## ⚡ Worker Script → `run_node.sh`

Dijalanin via systemd → pastikan docker compose selalu aktif.

---

## 📦 Re-Install / Move VPS

1) Copy identity:
```
/root/deklan/
```

2) Run:
```
bash <(curl -s https://raw.githubusercontent.com/deklan400/deklan-autoinstall/main/install.sh)
```

> ✅ Langsung running  
> ✅ Tidak perlu input ulang  

---

## ❌ Uninstall

```
systemctl stop gensyn
systemctl disable gensyn
rm /etc/systemd/system/gensyn.service
rm -rf /home/gensyn/rl_swarm
systemctl daemon-reload
```

---

## ✅ Contoh Output

```
[1/9] Checking identity... ✅
[2/9] Updating system...
[3/9] Installing dependencies...
[4/9] Installing Docker...
[5/9] Cloning RL-Swarm...
[6/9] Copying identity...
[7/9] Installing systemd...
[8/9] Starting RL-Swarm...
```

> ✔ Node berjalan sukses!

---

## 🔐 Keamanan

⚠ Jangan upload `swarm.pem` ke internet  
✅ Backup offline  
✅ Installer tidak kirim data ke server manapun  

---

<div align="center">

### ❤️ Built by **Deklan × GPT-5**
#### Dark-theme • Clean • Auto-Deploy

</div>

