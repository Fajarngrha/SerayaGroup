#!/bin/bash
# Setup DNS manual — record untuk Hostinger hPanel
# Jalankan: bash deploy/setup-dns-hostinger.sh

DOMAIN="sejahterarayagrup.com"
TUNNEL_ID="6bed7d36-e77d-4651-94ed-24efde5485b1"
CNAME_TARGET="${TUNNEL_ID}.cfargotunnel.com"

echo ""
echo "=============================================="
echo " DNS Manual — Hostinger (hPanel)"
echo " Domain: $DOMAIN"
echo "=============================================="
echo ""
echo "Login: https://hpanel.hostinger.com"
echo ""
echo "Langkah:"
echo "  1. Domains → $DOMAIN → DNS / DNS Zone"
echo "  2. Hapus record A/CNAME lama untuk @ dan www (jika ada)"
echo "  3. Tambahkan record berikut:"
echo ""
printf "  %-8s %-10s  %s\n" "TYPE" "NAME" "POINTS TO / TARGET"
printf "  %-8s %-10s  %s\n" "────" "────" "─────────────────"
printf "  %-8s %-10s  %s\n" "CNAME" "www"       "$CNAME_TARGET"
printf "  %-8s %-10s  %s\n" "CNAME" "@"         "$CNAME_TARGET"
echo ""
echo "Catatan Hostinger:"
echo "  - Field NAME: '@' = root domain, 'www' = subdomain www"
echo "  - TTL: 14400 atau default"
echo "  - Jika CNAME '@' ditolak, pakai www saja + Redirect domain"
echo "  - Redirect: hPanel → Domains → Redirects"
echo "    From: $DOMAIN → To: https://www.$DOMAIN"
echo ""
echo "Setelah save, tunggu 5-30 menit lalu:"
echo "  bash deploy/verify.sh"
echo ""

echo "--- Status DNS sekarang ---"
if command -v nslookup &>/dev/null; then
  nslookup "$DOMAIN" 2>&1 | tail -6
  echo ""
  nslookup "www.$DOMAIN" 2>&1 | tail -6
fi
echo ""
