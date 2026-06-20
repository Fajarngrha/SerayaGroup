#!/bin/bash
# Instalasi website Seraya di Raspberry Pi
# Jalankan: bash deploy/install.sh

set -e

APP_DIR="/home/pi/seraya-website"
SERVICE_WEB="seraya-website"
SERVICE_TUNNEL="cloudflared-tunnel"

echo "=========================================="
echo "  Instalasi Seraya Website - Raspberry Pi"
echo "=========================================="

# 1. Cek Node.js
if ! command -v node &> /dev/null; then
  echo "[!] Node.js belum terpasang."
  echo "    Install: curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -"
  echo "             sudo apt install -y nodejs"
  exit 1
fi
echo "[OK] Node.js $(node -v)"

# 2. Install dependencies
echo "[..] Menginstall dependencies..."
npm ci --omit=dev 2>/dev/null || npm install --omit=dev

# 3. Buat .env jika belum ada
if [ ! -f .env ]; then
  cp .env.example .env
  echo "[OK] File .env dibuat dari .env.example"
fi

# 4. Install systemd service - website
echo "[..] Menginstall systemd service: $SERVICE_WEB"
sudo cp deploy/systemd/seraya-website.service /etc/systemd/system/
sudo sed -i "s|/home/pi/seraya-website|$APP_DIR|g" /etc/systemd/system/seraya-website.service

sudo systemctl daemon-reload
sudo systemctl enable "$SERVICE_WEB"
sudo systemctl restart "$SERVICE_WEB"

echo "[OK] Service $SERVICE_WEB aktif"
sudo systemctl status "$SERVICE_WEB" --no-pager -l | head -5

# 5. Test health check
sleep 2
if curl -sf http://127.0.0.1:3000/health > /dev/null; then
  echo "[OK] Health check berhasil → http://127.0.0.1:3000/health"
else
  echo "[!] Health check gagal. Cek log: journalctl -u $SERVICE_WEB -f"
fi

echo ""
echo "=========================================="
echo "  Website berjalan di localhost:3000"
echo "  Langkah berikutnya: setup Cloudflare Tunnel"
echo "  Lihat: DEPLOY.md"
echo "=========================================="
