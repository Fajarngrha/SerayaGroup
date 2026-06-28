#!/bin/bash
# Perbaikan lengkap deploy di Raspberry Pi
# Jalankan dari folder project (contoh: ~/SerayaGroup):
#   cd ~/SerayaGroup
#   bash deploy/fix-all.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PI_USER="$(whoami)"
CF_CONFIG="/home/$PI_USER/.cloudflared/config.yml"
TUNNEL_ID="6bed7d36-e77d-4651-94ed-24efde5485b1"
PORT=3000

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

ok()   { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
fail() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

echo ""
echo "=========================================="
echo " Fix Deploy — Seraya Group"
echo " Folder: $APP_DIR"
echo " User:   $PI_USER"
echo "=========================================="
echo ""

# --- 1. Cek file deploy ada ---
if [ ! -f "$APP_DIR/deploy/systemd/seraya-website.service" ]; then
  fail "Folder deploy tidak ditemukan. Pastikan Anda di folder project yang benar.\n  cd ~/SerayaGroup\n  ls deploy/systemd/"
fi
ok "File deploy ditemukan"

# --- 2. Install & start website ---
cd "$APP_DIR"

if ! command -v node &>/dev/null; then
  fail "Node.js belum terpasang"
fi

echo "Install npm..."
npm install --omit=dev

[ -f .env ] || cp .env.example .env 2>/dev/null || true
grep -q "^PORT=" .env 2>/dev/null && sed -i "s/^PORT=.*/PORT=$PORT/" .env || echo "PORT=$PORT" >> .env
grep -q "^HOST=" .env 2>/dev/null && sed -i "s/^HOST=.*/HOST=127.0.0.1/" .env || echo "HOST=127.0.0.1" >> .env

# Buat service dengan path yang benar
sed -e "s|/home/fajar/SerayaGroup|$APP_DIR|g" \
    -e "s|User=fajar|User=$PI_USER|g" \
    -e "s|Group=fajar|Group=$PI_USER|g" \
    "$APP_DIR/deploy/systemd/seraya-website.service" \
    | sudo tee /etc/systemd/system/seraya-website.service > /dev/null

sudo systemctl daemon-reload
sudo systemctl enable seraya-website
sudo systemctl restart seraya-website
sleep 2

if curl -sf "http://127.0.0.1:$PORT/health" | grep -q ok; then
  ok "Website jalan di http://127.0.0.1:$PORT"
else
  warn "Website belum merespons. Log:"
  journalctl -u seraya-website -n 15 --no-pager
  fail "Gagal start website"
fi

# --- 3. Config cloudflared ---
mkdir -p "/home/$PI_USER/.cloudflared"

if [ -f "$CF_CONFIG" ]; then
  cp "$CF_CONFIG" "$CF_CONFIG.backup.$(date +%Y%m%d_%H%M%S)"
  ok "Backup config lama"
fi

cat > "$CF_CONFIG" << EOF
tunnel: $TUNNEL_ID
credentials-file: /home/$PI_USER/.cloudflared/$TUNNEL_ID.json

ingress:
  - hostname: fid-maintenance.online
    service: http://127.0.0.1:3001

  - hostname: sejahterarayagrup.com
    service: http://127.0.0.1:3000

  - hostname: www.sejahterarayagrup.com
    service: http://127.0.0.1:3000

  - service: http_status:404
EOF
ok "Config tunnel ditulis → $CF_CONFIG"

# --- 4. Cloudflared service ---
# Cek service yang sudah ada (jangan buat duplikat)
if systemctl list-unit-files | grep -q "^cloudflared.service"; then
  ok "Service cloudflared.service sudah ada — cukup restart"
  sudo systemctl restart cloudflared
elif systemctl is-active --quiet cloudflared 2>/dev/null; then
  ok "cloudflared sudah running — restart"
  sudo systemctl restart cloudflared
else
  warn "Membuat cloudflared.service baru..."
  CLOUDFLARED_BIN="$(command -v cloudflared || echo /usr/local/bin/cloudflared)"
  sudo tee /etc/systemd/system/cloudflared.service > /dev/null << EOF
[Unit]
Description=Cloudflare Tunnel
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=$PI_USER
ExecStart=$CLOUDFLARED_BIN tunnel --config $CF_CONFIG run
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
  sudo systemctl daemon-reload
  sudo systemctl enable cloudflared
  sudo systemctl restart cloudflared
  ok "cloudflared.service dibuat & dijalankan"
fi

sleep 2

# --- 5. Verifikasi ---
echo ""
echo "=========================================="
echo " Hasil"
echo "=========================================="

curl -sf "http://127.0.0.1:$PORT/health" && echo "" && ok "Website lokal OK" || warn "Website lokal GAGAL"

if systemctl is-active --quiet cloudflared; then
  ok "cloudflared service OK"
else
  warn "cloudflared tidak jalan — cek: journalctl -u cloudflared -n 20"
fi

echo ""
echo "Path project Anda: $APP_DIR"
echo ""
echo "JANGAN pakai cloudflared-tunnel.service — gunakan cloudflared.service yang sudah ada."
echo ""
echo "Langkah DNS (Hostinger/Cloudflare):"
echo "  bash deploy/setup-dns-hostinger.sh"
echo "  bash deploy/verify.sh"
echo ""
