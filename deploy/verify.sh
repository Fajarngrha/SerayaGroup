#!/bin/bash
# Verifikasi status deploy Seraya Group
# Jalankan: bash deploy/verify.sh

DOMAIN="sejahterarayagrup.com"
WWW_DOMAIN="www.sejahterarayagrup.com"
SERAYA_PORT=3000
OLD_PORT=3001

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

check() {
  local label="$1"
  local cmd="$2"
  echo -n "  $label ... "
  if eval "$cmd" &>/dev/null; then
    echo -e "${GREEN}OK${NC}"
    return 0
  else
    echo -e "${RED}GAGAL${NC}"
    return 1
  fi
}

echo ""
echo "========================================"
echo " Verifikasi Deploy Seraya Group"
echo "========================================"

PASS=0
TOTAL=0
run_check() { TOTAL=$((TOTAL + 1)); check "$1" "$2" && PASS=$((PASS + 1)); }

echo ""
echo "[ Services ]"
run_check "seraya-website" "systemctl is-active --quiet seraya-website"
run_check "cloudflared"      "systemctl is-active --quiet cloudflared"

echo ""
echo "[ Website lokal ]"
run_check "Port $SERAYA_PORT (Seraya)" "curl -sf http://127.0.0.1:$SERAYA_PORT/health | grep -q ok"
run_check "Port $OLD_PORT (site lama)"  "curl -sf -o /dev/null http://127.0.0.1:$OLD_PORT"

echo ""
echo "[ DNS ]"
run_check "DNS $DOMAIN"     "nslookup $DOMAIN"
run_check "DNS $WWW_DOMAIN" "nslookup $WWW_DOMAIN"

echo ""
echo "[ HTTPS publik ]"
run_check "https://$DOMAIN/health"     "curl -sf --max-time 15 https://$DOMAIN/health | grep -q ok"
run_check "https://$WWW_DOMAIN/health" "curl -sf --max-time 15 https://$WWW_DOMAIN/health | grep -q ok"

echo ""
echo "========================================"
echo -e " Hasil: ${PASS}/${TOTAL} cek berhasil"
echo "========================================"

if [ "$PASS" -eq "$TOTAL" ]; then
  echo -e "${GREEN}Semua OK — https://$DOMAIN${NC}"
elif curl -sf "http://127.0.0.1:$SERAYA_PORT/health" | grep -q ok; then
  echo -e "${YELLOW}Website lokal OK. DNS belum siap.${NC}"
  echo "  Hostinger: bash deploy/setup-dns-hostinger.sh"
  echo "  Cloudflare: deploy/PANDUAN-CLOUDFLARE-HOSTINGER.md"
else
  echo -e "${RED}Website belum jalan. Cek: journalctl -u seraya-website -n 20${NC}"
fi
echo ""
