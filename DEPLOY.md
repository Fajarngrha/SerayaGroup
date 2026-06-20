# Deploy ke Raspberry Pi + Tunnel + Domain Sendiri

Panduan ini men-deploy website **PT Sejahtera Raya Grup** di Raspberry Pi Anda, lalu mengeksposnya ke internet melalui **Cloudflare Tunnel** (tanpa buka port router / tanpa IP publik).

---

## Arsitektur

```
Internet → Domain Anda → Cloudflare Tunnel → localhost:3000 → Node.js (Express)
```

- Website hanya listen di `127.0.0.1:3000` (tidak terbuka ke LAN/internet)
- Tunnel menghubungkan domain → localhost
- Tidak perlu port forwarding di router

---

## Prasyarat

| Item | Keterangan |
|------|------------|
| Raspberry Pi | OS Raspberry Pi OS / Debian (ARM64 atau ARM32) |
| Domain | Sudah punya domain sendiri |
| Cloudflare | Domain di-manage di Cloudflare (gratis) |
| Node.js | v18+ (`node -v`) |

---

## Langkah 1 — Salin project ke Raspberry Pi

### Opsi A: Git (disarankan)

Di Raspberry Pi:

```bash
cd ~
git clone <URL-REPO-ANDA> seraya-website
cd seraya-website
```

### Opsi B: SCP dari komputer Windows

Di PowerShell (ganti IP Pi Anda):

```powershell
scp -r d:\Seraya_Project pi@192.168.1.100:~/seraya-website
```

---

## Langkah 2 — Install & jalankan website

```bash
cd ~/seraya-website
bash deploy/install.sh
```

Script ini akan:
- Install dependency npm
- Buat file `.env`
- Register systemd service `seraya-website`
- Auto-start saat Pi boot

### Perintah berguna

```bash
# Status service
sudo systemctl status seraya-website

# Restart setelah update
sudo systemctl restart seraya-website

# Lihat log
journalctl -u seraya-website -f

# Test lokal
curl http://127.0.0.1:3000/health
```

---

## Langkah 3 — Install Cloudflare Tunnel

### 3.1 Install cloudflared

**Raspberry Pi 4/5 (64-bit):**

```bash
curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64.deb -o cloudflared.deb
sudo dpkg -i cloudflared.deb
```

**Raspberry Pi lama (32-bit):**

```bash
curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm.deb -o cloudflared.deb
sudo dpkg -i cloudflared.deb
```

### 3.2 Login Cloudflare

```bash
cloudflared tunnel login
```

Browser terbuka → pilih domain Anda → authorize.

### 3.3 Buat tunnel

```bash
cloudflared tunnel create seraya-website
cloudflared tunnel list
```

Catat **Tunnel ID (UUID)** yang muncul.

### 3.4 Buat config tunnel

```bash
mkdir -p ~/.cloudflared
cp ~/seraya-website/deploy/cloudflared/config.yml.example ~/.cloudflared/config.yml
nano ~/.cloudflared/config.yml
```

Edit isi file (ganti dengan nilai Anda):

```yaml
tunnel: <TUNNEL-UUID>
credentials-file: /home/pi/.cloudflared/<TUNNEL-UUID>.json

ingress:
  - hostname: www.domain-anda.com
    service: http://127.0.0.1:3000
  - hostname: domain-anda.com
    service: http://127.0.0.1:3000
  - service: http_status:404
```

### 3.5 Route DNS

```bash
cloudflared tunnel route dns seraya-website www.domain-anda.com
cloudflared tunnel route dns seraya-website domain-anda.com
```

### 3.6 Jalankan tunnel sebagai service

```bash
sudo cp ~/seraya-website/deploy/systemd/cloudflared.service /etc/systemd/system/cloudflared-tunnel.service
sudo systemctl daemon-reload
sudo systemctl enable cloudflared-tunnel
sudo systemctl start cloudflared-tunnel
sudo systemctl status cloudflared-tunnel
```

---

## Langkah 4 — Verifikasi

```bash
# Health check lokal
curl http://127.0.0.1:3000/health

# Health check via domain (dari Pi atau browser)
curl https://www.domain-anda.com/health
```

Response yang diharapkan:

```json
{"status":"ok","service":"seraya-website"}
```

Buka browser: `https://www.domain-anda.com`

---

## Update website setelah deploy

```bash
cd ~/seraya-website
git pull                    # atau salin ulang file
npm ci --omit=dev             # jika package.json berubah
sudo systemctl restart seraya-website
```

---

## Tunnel alternatif

Jika **bukan** Cloudflare, prinsipnya sama: tunnel → `http://127.0.0.1:3000`

| Tunnel | Catatan |
|--------|---------|
| **Tailscale Funnel** | Mudah jika sudah pakai Tailscale |
| **ngrok** | Cepat untuk testing, domain custom butuh plan berbayar |
| **WireGuard + VPS reverse proxy** | Lebih advanced |

---

## Keamanan

- Website bind ke `127.0.0.1` saja — tidak expose port ke jaringan
- Jangan buka port 3000 di firewall/router
- HTTPS ditangani Cloudflare Tunnel otomatis
- Update Pi rutin: `sudo apt update && sudo apt upgrade`

---

## Troubleshooting

| Masalah | Solusi |
|---------|--------|
| `502 Bad Gateway` | Cek website jalan: `systemctl status seraya-website` |
| Tunnel tidak connect | `journalctl -u cloudflared-tunnel -f` |
| Domain tidak resolve | Cek DNS di Cloudflare dashboard |
| Node tidak ditemukan | Install Node.js 20 LTS dari nodesource |
| Permission denied | Pastikan user `pi` punya akses ke folder project |

---

## Struktur file deploy

```
deploy/
├── install.sh              # Instalasi otomatis di Pi
├── setup-tunnel.sh         # Panduan interaktif tunnel
├── systemd/
│   ├── seraya-website.service
│   └── cloudflared.service
└── cloudflared/
    └── config.yml.example
```
