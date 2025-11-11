<!-- DARK MODE STYLED README -->

<div align="center">

# 🌙🚀 GENSYN RL-SWARM NODE  
### ⚡ ONE-COMMAND AUTO INSTALLER + SYSTEMD (CPU-ONLY)

> Deploy RL-Swarm Testnet Node dalam hitungan detik — auto, simple, stabil.

<img src="https://img.shields.io/badge/Gensyn-RL--Swarm-0a84ff?style=for-the-badge"/>
<img src="https://img.shields.io/badge/Auto_Install-00d18a?style=for-the-badge"/>
<img src="https://img.shields.io/badge/CPU_Only-0066ff?style=for-the-badge"/>
<img src="https://img.shields.io/badge/Systemd-AutoStart-fd8a09?style=for-the-badge"/>

</div>

---

> 🆕 **SMART MODE**
- Jika **NEW USER → Auto buka WebUI → login → identity otomatis terbentuk**
- Jika **EXISTING USER → Langsung jalan**

---

## ✅ Fitur

✔ CPU-only  
✔ Install dependencies  
✔ Install Docker  
✔ Clone RL-Swarm  
✔ Auto detect NEW/EXISTING user  
✔ NEW USER → Auto open WebUI → generate identity  
✔ EXISTING USER → Auto link identity  
✔ Auto create symlink  
✔ Setup systemd service  
✔ Auto restart jika mati  
✔ Migrate VPS gampang  
✔ Clean + simple  

---

## ✅ Identity Files

| File | Fungsi |
|------|--------|
| swarm.pem | Private key |
| userApiKey.json | API credential |
| userData.json | Metadata akun |

Lokasi penyimpanan:

```
/root/deklan/
```

✅ NEW USER → file dibuat otomatis  
✅ EXISTING USER → wajib ada 3 file ini  

---

## 🚀 Instalasi

> Jalankan 1 baris:

```bash
bash <(curl -s https://raw.githubusercontent.com/deklan400/deklan-autoinstall/main/install.sh)
```

✅ NEW USER → auto login WebUI → lanjut  
✅ EXISTING USER → langsung daemon  

---

## 📂 Struktur Folder

```
/root/deklan/
│── swarm.pem
│── userApiKey.json
└── userData.json

/root/rl-swarm/
│── user/
│   └── keys → symlink → /root/deklan
│── docker-compose.yaml
│── run_node.sh
│── .env
└── ...
```

Symlink:
```
/root/rl-swarm/user/keys → /root/deklan
```

---

## ✅ Status Node

```
systemctl status gensyn --no-pager
```

Realtime log:
```
journalctl -u gensyn -f
```

---

## 🔁 Restart Node

```
systemctl restart gensyn
```

Atau:
```bash
bash <(curl -s https://raw.githubusercontent.com/deklan400/deklan-autoinstall/main/restart.sh)
```

---

## 🔄 Update Node

```
bash <(curl -s https://raw.githubusercontent.com/deklan400/deklan-autoinstall/main/update.sh)
```

---

## 🔁 Reinstall
> 🔐 Tidak menghapus identity

```
bash <(curl -s https://raw.githubusercontent.com/deklan400/deklan-autoinstall/main/reinstall.sh)
```

---

## ❌ Uninstall

> Identity tetap aman

```
bash <(curl -s https://raw.githubusercontent.com/deklan400/deklan-autoinstall/main/uninstall.sh)
```

Jika ingin hapus identity:
```
REMOVE_KEYS=1 bash uninstall.sh
```

---

## ⚡ Path Penting

| Resource | Path |
|----------|------|
| Identity | `/root/deklan/` |
| Repo | `/root/rl-swarm/` |
| Keys (symlink) | `/root/rl-swarm/user/keys` |
| Service | `/etc/systemd/system/gensyn.service` |

---

## ✅ Contoh Output

```
[1] Detect mode → NEW
[2] Install Docker...
[3] Clone RL-Swarm...
[4] Start CPU node...
[5] Tunnel ready → open browser & login
[6] Identity detected → continue
[7] Systemd active
✅ Done — node running
```

---

## 🔐 Keamanan

⚠ `swarm.pem` = PRIVATE KEY  
→ Jangan upload online  
→ Backup offline  
→ Script lokal — tidak mengirim data keluar  

---

## 🧯 Troubleshooting

| Masalah | Solusi |
|--------|--------|
| Node mati | systemctl restart gensyn |
| No log | journalctl -u gensyn -f |
| Identity tidak muncul | Login ulang WebUI |
| Repo rusak | reinstall.sh |
| Docker penuh | docker system prune -af |

---

<div align="center">

### ✅ Built by **Deklan × GPT-5**  
Dark • Fast • Clean

</div>

