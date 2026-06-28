#!/bin/bash
# Update website setelah ada perubahan kode
# Jalankan di Pi: cd ~/SerayaGroup && bash deploy/update.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo ""
echo "=========================================="
echo " Update Seraya Website"
echo " Folder: $APP_DIR"
echo "=========================================="

cd "$APP_DIR"

# 1. Pull dari git (jika pakai git)
if [ -d .git ]; then
  echo "[1] git pull..."
  git pull
else
  echo "[1] Skip git pull (bukan repo git)"
  echo "    Salin file dari PC jika belum: scp -r ..."
fi

# 2. Install dependency jika package.json berubah
echo "[2] npm install..."
npm install --omit=dev

# 3. Restart website
echo "[3] Restart seraya-website..."
sudo systemctl restart seraya-website
sleep 2

# 4. Verifikasi
echo "[4] Health check..."
if curl -sf http://127.0.0.1:3000/health | grep -q ok; then
  echo ""
  echo "=========================================="
  echo " Update berhasil!"
  echo " https://sejahterarayagrup.com"
  echo "=========================================="
else
  echo ""
  echo "Gagal! Cek log:"
  echo "  journalctl -u seraya-website -n 30 --no-pager"
  exit 1
fi

echo ""
echo "Catatan:"
echo "  - Restart cloudflared TIDAK perlu (kecuali config tunnel berubah)"
echo "  - Hard refresh browser: Ctrl+Shift+R"
echo ""
