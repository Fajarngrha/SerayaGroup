#!/bin/bash
# Perbaikan cepat: jalankan website Seraya di port 3000
# Jalankan di Pi: bash deploy/fix-deploy.sh

set -e

APP_DIR="/home/fajar/SerayaGroup"
SERVICE="seraya-website"

echo "=== Fix Deploy Seraya Website ==="

cd "$APP_DIR"

# 1. Install dependencies
echo "[1/4] Install dependencies..."
npm install --omit=dev

# 2. Buat .env
if [ ! -f .env ]; then
  cp .env.example .env
fi
grep -q "^PORT=" .env || echo "PORT=3000" >> .env
grep -q "^HOST=" .env || echo "HOST=127.0.0.1" >> .env

# 3. Install & start systemd
echo "[2/4] Setup systemd service..."
sudo cp deploy/systemd/seraya-website.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable "$SERVICE"
sudo systemctl restart "$SERVICE"

sleep 2

# 4. Health check
echo "[3/4] Health check..."
if curl -sf http://127.0.0.1:3000/health; then
  echo ""
  echo "[OK] Website Seraya berjalan di port 3000"
else
  echo "[!] Gagal. Cek log:"
  echo "    journalctl -u $SERVICE -n 30 --no-pager"
  exit 1
fi

echo ""
echo "[4/4] Langkah berikutnya — edit tunnel config:"
echo "  nano ~/.cloudflared/config.yml"
echo ""
echo "  Tambahkan SEBELUM baris 'http_status:404':"
echo "    - hostname: www.domain-anda.com"
echo "      service: http://127.0.0.1:3000"
echo ""
echo "  Lalu:"
echo "  cloudflared tunnel route dns web-pi www.domain-anda.com"
echo "  sudo systemctl restart cloudflared"
echo ""
echo "  Lihat contoh lengkap: deploy/cloudflared/config-multi-site.yml.example"
