<!-- DARK MODE STYLED README -->

<div align="center">

# 🌙🚀 GENSYN RL-SWARM  
### ⚡ ONE-COMMAND AUTO INSTALLER

> **Deploy RL-Swarm Node dalam 10 detik — aman, cepat, auto-management**  

<img src="https://img.shields.io/badge/Gensyn-RL--Swarm-0a84ff?style=for-the-badge"/>
<img src="https://img.shields.io/badge/Auto_Installer-00d18a?style=for-the-badge"/>
<img src="https://img.shields.io/badge/Systemd-AutoStart-fd8a09?style=for-the-badge"/>
<img src="https://img.shields.io/badge/Copy_And_Run-1_Step-lightgrey?style=for-the-badge"/>

</div>

---

<p align="center">
<img width="85%" src="assets/dark-preview.png" />
</p>

> ✅ Jika preview belum muncul → upload screenshot ke folder:  
`/assets/dark-preview.png`

---

## ✅ Fitur Utama

✔ Validasi identity  
✔ Install dependencies  
✔ Install Docker  
✔ Clone RL-Swarm  
✔ Link identity → `/keys/`  
✔ Setup systemd service  
✔ Auto-start + autorestart  
✔ Bisa untuk multi server / migrasi VPS  

---

## 📁 Persiapan Identity (WAJIB)

Siapkan **3 file** berikut:

| File | Fungsi |
|------|--------|
| `swarm.pem` | Private key |
| `userApiKey.json` | API Credential |
| `userData.json` | User / Account Data |

Upload →  
```
/root/deklan/
```

Jika salah satu file hilang → installer otomatis berhenti ⚠️  

---

## 🚀 Quick Install (1 Command)

> Pastikan 3 identity sudah berada di:
> `/root/deklan/`

```bash
bash <(curl -s https://raw.githubusercontent.com/deklan400/deklan-autoinstall/main/install.sh)
```

✅ Node auto jalan  
✅ Auto restart enable  
✅ No config needed  

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
└── source ...
```

Identity otomatis →  
```
/root/rl_swarm/keys/
```

---

## 📊 Cek Status Node

Status:
```bash
systemctl status gensyn
```

Log realtime:
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

---

## 🔁 Reinstall

> 🟡 Tidak menghapus identity

```bash
bash <(curl -s https://raw.githubusercontent.com/deklan400/deklan-autoinstall/main/reinstall.sh)
```

---

## ❌ Uninstall

> Identity **tidak dihapus**

```bash
bash <(curl -s https://raw.githubusercontent.com/deklan400/deklan-autoinstall/main/uninstall.sh)
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

## 🧠 Notes

✔ Bisa dipindah ke VPS lain  
✔ Minimal potongan config  
✔ Automatic update git saat node dijalankan  
✔ Docker build otomatis  

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
✅ DONE
```

> Node berhasil berjalan ✅

---

## 🔐 Keamanan

⚠ `swarm.pem` adalah private key  
✅ Jangan disimpan online  
✅ Simpan backup offline  
✅ Installer **tidak kirim data ke server mana pun**  

---

<div align="center">

### ✅ Built by **Deklan × GPT-5**  
Dark • Clean • Minimal

</div>
