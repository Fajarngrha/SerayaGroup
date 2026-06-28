#!/bin/bash
# Update domain ke sejahterarayagrup.com
# Jalankan di Pi: bash deploy/update-domain.sh

set -e

DOMAIN="sejahterarayagrup.com"
WWW="www.sejahterarayagrup.com"
TUNNEL_NAME="web-pi"
TUNNEL_ID="6bed7d36-e77d-4651-94ed-24efde5485b1"
PI_USER="$(whoami)"
CF_CONFIG="/home/$PI_USER/.cloudflared/config.yml"

echo "=== Update domain → $DOMAIN ==="

# 1. Update config tunnel
mkdir -p "/home/$PI_USER/.cloudflared"
[ -f "$CF_CONFIG" ] && cp "$CF_CONFIG" "$CF_CONFIG.backup.$(date +%Y%m%d_%H%M%S)"

cat > "$CF_CONFIG" << EOF
tunnel: $TUNNEL_ID
credentials-file: /home/$PI_USER/.cloudflared/$TUNNEL_ID.json

ingress:
  - hostname: fid-maintenance.online
    service: http://127.0.0.1:3001

  - hostname: $DOMAIN
    service: http://127.0.0.1:3000

  - hostname: $WWW
    service: http://127.0.0.1:3000

  - service: http_status:404
EOF

echo "[OK] Config tunnel updated"
cat "$CF_CONFIG"

# 2. Route DNS di Cloudflare
echo ""
echo "Routing DNS..."
cloudflared tunnel route dns "$TUNNEL_NAME" "$DOMAIN" || echo "[!] Route $DOMAIN — set manual di Cloudflare Dashboard"
cloudflared tunnel route dns "$TUNNEL_NAME" "$WWW" || echo "[!] Route $WWW — set manual di Cloudflare Dashboard"

# 3. Restart services
sudo systemctl restart seraya-website
sudo systemctl restart cloudflared
sleep 2

echo ""
echo "=== Verifikasi ==="
curl -sf "http://127.0.0.1:3000/health" && echo "" || echo "[!] Website lokal gagal"
bash "$(dirname "$0")/verify.sh"
