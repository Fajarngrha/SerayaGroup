#!/bin/bash
# Fix 404 — sejahterarayagrup.com
# Jalankan: cd ~/SerayaGroup && bash deploy/fix-404.sh

set -e

DOMAIN="sejahterarayagrup.com"
WWW="www.sejahterarayagrup.com"
TUNNEL_ID="6bed7d36-e77d-4651-94ed-24efde5485b1"
PI_USER="$(whoami)"
CF_CONFIG="/home/$PI_USER/.cloudflared/config.yml"
CRED="/home/$PI_USER/.cloudflared/${TUNNEL_ID}.json"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo ""
echo "=========================================="
echo " FIX 404 — $DOMAIN"
echo "=========================================="

# ── 1. Website lokal ──
echo ""
echo "[1] Website lokal..."
if curl -sf "http://127.0.0.1:3000/health" | grep -q ok; then
  echo -e "  ${GREEN}OK${NC} http://127.0.0.1:3000/health"
else
  echo -e "  ${RED}GAGAL${NC} — start website dulu"
  sudo systemctl restart seraya-website
  sleep 2
  curl -sf "http://127.0.0.1:3000/health" || { echo "  Fix: bash deploy/fix-all.sh"; exit 1; }
fi

# ── 2. Credentials ──
echo ""
echo "[2] File credentials..."
if [ ! -f "$CRED" ]; then
  echo -e "  ${RED}GAGAL${NC} $CRED tidak ada!"
  exit 1
fi
echo -e "  ${GREEN}OK${NC} $CRED"

# ── 3. Tulis config tunnel yang benar ──
echo ""
echo "[3] Tulis config tunnel..."
mkdir -p "/home/$PI_USER/.cloudflared"
[ -f "$CF_CONFIG" ] && cp "$CF_CONFIG" "$CF_CONFIG.bak"

cat > "$CF_CONFIG" << EOF
tunnel: $TUNNEL_ID
credentials-file: $CRED

ingress:
  - hostname: fid-maintenance.online
    service: http://127.0.0.1:3001

  - hostname: $DOMAIN
    service: http://127.0.0.1:3000

  - hostname: $WWW
    service: http://127.0.0.1:3000

  - service: http_status:404
EOF

echo -e "  ${GREEN}OK${NC} config ditulis"
cat "$CF_CONFIG" | sed 's/^/    /'

# ── 4. Pastikan cloudflared pakai config ini ──
echo ""
echo "[4] Service cloudflared..."
CLOUDFLARED_BIN="$(command -v cloudflared)"

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
sleep 3

if systemctl is-active --quiet cloudflared; then
  echo -e "  ${GREEN}OK${NC} cloudflared running"
else
  echo -e "  ${RED}GAGAL${NC} — log:"
  journalctl -u cloudflared -n 15 --no-pager
  exit 1
fi

# ── 5. Test ──
echo ""
echo "[5] Test..."
echo -n "  Lokal /health ... "
curl -sf "http://127.0.0.1:3000/health" && echo "" || echo "GAGAL"

echo -n "  HTTPS /health ... "
HTTP=$(curl -sf -o /tmp/health_out -w "%{http_code}" --max-time 15 "https://$DOMAIN/health" 2>/dev/null || echo "000")
if [ "$HTTP" = "200" ]; then
  echo -e "${GREEN}HTTP 200 OK${NC}"
  cat /tmp/health_out
  echo ""
else
  echo -e "${RED}HTTP $HTTP${NC}"
fi

echo ""
echo "=========================================="
echo -e "${YELLOW} PENTING — Cloudflare Dashboard${NC}"
echo "=========================================="
echo ""
echo "  JANGAN pakai: cloudflared tunnel route dns"
echo "  (Itu buat subdomain salah di fid-maintenance.online)"
echo ""
echo "  Di zone ${GREEN}sejahterarayagrup.com${NC} → DNS → Records:"
echo "    CNAME @   → ${TUNNEL_ID}.cfargotunnel.com  (Proxied ON)"
echo "    CNAME www → ${TUNNEL_ID}.cfargotunnel.com  (Proxied ON)"
echo "    → Klik SAVE jika masih mode edit!"
echo ""
echo "  Di zone ${RED}fid-maintenance.online${NC} → DNS → HAPUS jika ada:"
echo "    ✗ sejahterarayagrup.com.fid-maintenance.online"
echo "    ✗ www.sejahterarayagrup.com.fid-maintenance.online"
echo ""
echo "  Test dari PC:"
echo "    curl.exe https://$DOMAIN/health"
echo "    curl.exe https://$WWW"
echo ""
