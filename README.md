<!-- DARK MODE STYLED README -->

<div align="center">

# 🌙🚀 GENSYN RL-SWARM  
### ⚡ ONE-COMMAND AUTO INSTALLER + SYSTEMD MANAGER

> **Deploy RL-Swarm Node hanya dalam 10 detik — aman, cepat, auto-management.**

<img src="https://img.shields.io/badge/Gensyn-RL--Swarm-0a84ff?style=for-the-badge"/>
<img src="https://img.shields.io/badge/Auto_Installer-00d18a?style=for-the-badge"/>
<img src="https://img.shields.io/badge/Systemd-AutoStart-fd8a09?style=for-the-badge"/>
<img src="https://img.shields.io/badge/Copy_And_Run-1_Step-lightgrey?style=for-the-badge"/>

</div>

---

<p align="center">
  <img width="85%" src="assets/dark-preview.png" />
</p>

> ✅ Jika screenshot belum muncul → upload file ke:  
`/assets/dark-preview.png`

---

## ✅ Fitur Utama

✔ Validasi identity  
✔ Install dependencies  
✔ Install Docker  
✔ Clone RL-Swarm  
✔ Link identity → `/keys/` (symlink)  
✔ Auto-create `.env`  
✔ Setup systemd service  
✔ Auto-start + auto-restart  
✔ Git auto-update on run  
✔ Bisa multi VPS / migrasi cepat  

---

## ✅ Requirement

| Komponen | Status |
|---------|--------|
| Ubuntu 20 / 22 / 24 | ✅ |
| RAM 2GB+ | ✅ |
| Disk 10GB+ | ✅ |
| Internet stabil | ✅ |
| Identity lengkap (3 file) | ✅ |

---

## 📁 Identity (WAJIB)

Siapkan **3 file** berikut:

| File | Fungsi |
|------|--------|
| `swarm.pem` | Private key |
| `userApiKey.json` | API Credential |
| `userData.json` | Account Data |

Upload →  
```
/root/deklan/
```

Jika salah satu tidak ada → **installer otomatis berhenti** ⚠️  

---

## 🚀 Quick Install (1 Command)

> Pastikan identity sudah ada di:
> `/root/deklan/`

```bash
bash <(curl -s https://raw.githubusercontent.com/deklan400/deklan-autoinstall/main/install.sh)
```

✅ Node langsung jalan  
✅ Auto restart enable  
✅ Tanpa config manual  

---

## 📂 Struktur Folder

```
/root/deklan/
│── swarm.pem
│── userApiKey.json
└── userData.json

/root/rl_swarm/
│── keys/   → symlink ke /root/deklan
│── docker-compose.yaml
│── .env
└── src ...
```

Identity otomatis →  
```
/root/rl_swarm/keys/
```

---

## ✅ Status Node

```bash
systemctl status gensyn
```

Real-time logs:
```bash
journalctl -u gensyn -f
```

---

## 🔁 Restart Node

```bash
systemctl restart gensyn
```

Atau:
```bash
bash <(curl -s https://raw.githubusercontent.com/deklan400/deklan-autoinstall/main/restart.sh)
```

---

## 🔄 Update

```bash
bash <(curl -s https://raw.githubusercontent.com/deklan400/deklan-autoinstall/main/update.sh)
```

Modes:  
| Mode | Fungsi |
|------|--------|
| Normal | update repo |
| FAST | skip docker rebuild |
| FULL | force docker rebuild |

---

## 🔁 Reinstall

> ✅ Tidak menghapus identity

```bash
bash <(curl -s https://raw.githubusercontent.com/deklan400/deklan-autoinstall/main/reinstall.sh)
```

---

## ❌ Uninstall

> Identity **tidak dihapus**

```bash
bash <(curl -s https://raw.githubusercontent.com/deklan400/deklan-autoinstall/main/uninstall.sh)
```

Opsional:
```
REMOVE_KEYS=1 bash uninstall.sh
FULL_WIPE=1   bash uninstall.sh
```

---

## ⚡ Lokasi Penting

| Resource | Path |
|----------|------|
| Service file | `/etc/systemd/system/gensyn.service` |
| Repo folder  | `/root/rl_swarm/` |
| Keys folder  | `/root/rl_swarm/keys/` |
| Identity folder | `/root/deklan/` |

---

## ✅ Contoh Output

```
[1/9] Checking identity... ✅
[2/9] Updating system...
[3/9] Installing dependencies...
[4/9] Installing Docker...
[5/9] Cloning RL-Swarm...
[6/9] Symlinking identity...
[7/9] Preparing env...
[8/9] Starting RL-Swarm...
✅ DONE — NODE ACTIVE
```

---

## 🔐 Keamanan

⚠ `swarm.pem` = private key → **jangan upload online**  
✅ Simpan backup offline  
✅ Script **tidak kirim data kemanapun**  
✅ Semua proses lokal  

---

## 🧯 Troubleshooting

| Masalah | Solusi |
|--------|--------|
| Node mati | `systemctl restart gensyn` |
| Tidak ada log | `journalctl -u gensyn -f` |
| Identity error | Cek `/root/deklan/*` |
| Repo rusak | `rm -rf /root/rl_swarm` + reinstall |
| Docker error | `docker system prune -af` |

---

## 🌍 English Version

✅ One-click RL-Swarm installer  
✅ Auto systemd service  
✅ Identity symlink  
✅ Auto-restart  
✅ Easy multi-server migration  

Install:
```bash
bash <(curl -s https://raw.githubusercontent.com/deklan400/deklan-autoinstall/main/install.sh)
```

---

<div align="center">

### ✅ Built by **Deklan × GPT-5**  
Dark • Fast • Clean

</div>
