#!/bin/bash
# Setup Cloudflare Tunnel di Raspberry Pi
# Prasyarat: domain sudah di Cloudflare, cloudflared terinstall
#
# Install cloudflared (ARM64 Raspberry Pi):
#   curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64.deb -o cloudflared.deb
#   sudo dpkg -i cloudflared.deb
#
# Jalankan: bash deploy/setup-tunnel.sh

set -e

TUNNEL_NAME="seraya-website"
CONFIG_DIR="/home/pi/.cloudflared"
APP_PORT=3000

echo "=========================================="
echo "  Setup Cloudflare Tunnel"
echo "=========================================="

if ! command -v cloudflared &> /dev/null; then
  echo "[!] cloudflared belum terpasang."
  echo "    Download: https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/downloads/"
  exit 1
fi

mkdir -p "$CONFIG_DIR"

echo ""
echo "Langkah 1: Login ke Cloudflare"
echo "  cloudflared tunnel login"
echo ""
echo "Langkah 2: Buat tunnel"
echo "  cloudflared tunnel create $TUNNEL_NAME"
echo ""
echo "Langkah 3: Salin & edit config"
echo "  cp deploy/cloudflared/config.yml.example $CONFIG_DIR/config.yml"
echo "  nano $CONFIG_DIR/config.yml"
echo ""
echo "Langkah 4: Route DNS domain ke tunnel"
echo "  cloudflared tunnel route dns $TUNNEL_NAME www.serayagroup.com"
echo "  cloudflared tunnel route dns $TUNNEL_NAME serayagroup.com"
echo ""
echo "Langkah 5: Install & jalankan sebagai service"
echo "  sudo cp deploy/systemd/cloudflared.service /etc/systemd/system/cloudflared-tunnel.service"
echo "  sudo systemctl daemon-reload"
echo "  sudo systemctl enable cloudflared-tunnel"
echo "  sudo systemctl start cloudflared-tunnel"
echo ""
echo "Langkah 6: Verifikasi"
echo "  sudo systemctl status cloudflared-tunnel"
echo "  curl https://www.serayagroup.com/health"
echo ""
echo "Port lokal yang di-tunnel: http://127.0.0.1:$APP_PORT"
echo "=========================================="
