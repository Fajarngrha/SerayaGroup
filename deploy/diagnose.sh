#!/bin/bash
# Diagnostik lengkap — jalankan di Raspberry Pi:
#   cd ~/SerayaGroup && bash deploy/diagnose.sh

DOMAIN="sejahterarayagrup.com"
WWW="www.sejahterarayagrup.com"
PORT=3000
TUNNEL_ID="6bed7d36-e77d-4651-94ed-24efde5485b1"
CNAME_TARGET="${TUNNEL_ID}.cfargotunnel.com"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

pass() { echo -e "  ${GREEN}✓${NC} $1"; }
fail() { echo -e "  ${RED}✗${NC} $1"; }
warn() { echo -e "  ${YELLOW}!${NC} $1"; }
section() { echo ""; echo "=== $1 ==="; }

echo ""
echo "=========================================="
echo " DIAGNOSA: $DOMAIN"
echo "=========================================="

# 1. WEBSITE LOKAL
section "1. Website lokal (port $PORT)"
if curl -sf "http://127.0.0.1:$PORT/health" 2>/dev/null | grep -q ok; then
  pass "Website jalan → http://127.0.0.1:$PORT/health"
  curl -sf "http://127.0.0.1:$PORT/health"
  echo ""
else
  fail "Website TIDAK jalan di port $PORT"
  echo "     Fix: sudo systemctl start seraya-website"
  echo "     Log: journalctl -u seraya-website -n 20 --no-pager"
fi

if systemctl is-active --quiet seraya-website 2>/dev/null; then
  pass "Service seraya-website: active"
else
  fail "Service seraya-website: tidak active"
fi

# 2. CLOUDFLARED
section "2. Cloudflare Tunnel"
if systemctl is-active --quiet cloudflared 2>/dev/null; then
  pass "Service cloudflared: active"
else
  fail "Service cloudflared: tidak active"
  echo "     Fix: sudo systemctl start cloudflared"
fi

CF_CONFIG="$HOME/.cloudflared/config.yml"
CRED_FILE="$HOME/.cloudflared/${TUNNEL_ID}.json"

if [ -f "$CF_CONFIG" ]; then
  pass "Config ada: $CF_CONFIG"
else
  fail "Config tidak ada: $CF_CONFIG"
fi

if [ -f "$CRED_FILE" ]; then
  pass "Credentials ada: $CRED_FILE"
else
  fail "Credentials TIDAK ada: $CRED_FILE"
  echo "     File .json wajib ada untuk tunnel jalan"
fi

if [ -f "$CF_CONFIG" ]; then
  if grep -q "\.json" "$CF_CONFIG"; then
    pass "credentials-file punya ekstensi .json"
  else
    fail "credentials-file HARUS berakhiran .json"
    echo "     Fix: nano ~/.cloudflared/config.yml"
  fi

  if grep -q "hostname: $DOMAIN" "$CF_CONFIG"; then
    pass "Config punya hostname: $DOMAIN"
  else
    fail "Config TIDAK punya hostname: $DOMAIN"
    echo "     Fix: tambahkan di ingress config.yml"
  fi

  if grep -q "hostname: $WWW" "$CF_CONFIG"; then
    pass "Config punya hostname: $WWW"
  else
    warn "Config belum punya $WWW (www mungkin 404)"
  fi

  if grep -q "127.0.0.1:$PORT" "$CF_CONFIG"; then
    pass "Config arahkan ke port $PORT"
  else
    fail "Config tidak arahkan ke port $PORT"
  fi

  echo ""
  echo "  Isi config saat ini:"
  cat "$CF_CONFIG" | sed 's/^/    /'
fi

# 3. DNS
section "3. DNS"
check_dns() {
  local host="$1"
  echo "  nslookup $host:"
  local result
  result=$(nslookup "$host" 2>&1)
  echo "$result" | sed 's/^/    /'

  if echo "$result" | grep -qi "cfargotunnel\|cloudflare"; then
    pass "DNS $host → Cloudflare Tunnel OK"
    return 0
  elif echo "$result" | grep -qi "can't find\|NXDOMAIN"; then
    fail "DNS $host → BELUM TERDAFTAR (NXDOMAIN)"
    return 1
  else
    warn "DNS $host → mungkin belum ke tunnel (cek Hostinger/Cloudflare)"
    return 1
  fi
}

check_dns "$DOMAIN"
check_dns "$WWW"

# 4. TEST HTTPS
section "4. Test HTTPS publik"
for url in "https://$DOMAIN/health" "https://$DOMAIN/" "https://$WWW/health"; do
  echo -n "  $url ... "
  code=$(curl -sf -o /dev/null -w "%{http_code}" --max-time 10 "$url" 2>/dev/null || echo "000")
  if [ "$code" = "200" ]; then
    echo -e "${GREEN}HTTP $code OK${NC}"
  elif [ "$code" = "404" ]; then
    echo -e "${RED}HTTP 404${NC} ← hostname/DNS/config mismatch"
  elif [ "$code" = "502" ] || [ "$code" = "503" ]; then
    echo -e "${RED}HTTP $code${NC} ← website lokal tidak jalan"
  elif [ "$code" = "000" ]; then
    echo -e "${RED}Tidak bisa connect${NC} ← DNS belum resolve"
  else
    echo -e "${YELLOW}HTTP $code${NC}"
  fi
done

# 5. LOG TERAKHIR
section "5. Log cloudflared (5 baris terakhir)"
journalctl -u cloudflared -n 5 --no-pager 2>/dev/null | sed 's/^/  /' || warn "Tidak bisa baca log"

# RINGKASAN
section "RINGKASAN & FIX"
echo ""
echo "  Penyebab 404 paling umum:"
echo ""
echo "  [A] Website lokal mati"
echo "      → sudo systemctl restart seraya-website"
echo "      → curl http://127.0.0.1:3000/health"
echo ""
echo "  [B] DNS belum ke tunnel (masih Hostinger)"
echo "      → Hostinger hPanel → DNS → CNAME @ dan www ke:"
echo "        $CNAME_TARGET"
echo ""
echo "  [C] Hostname config.yml tidak cocok"
echo "      → Pastikan ada: sejahterarayagrup.com dan www.sejahterarayagrup.com"
echo "      → credentials-file harus .json"
echo "      → sudo systemctl restart cloudflared"
echo ""
echo "  [D] Domain belum di Cloudflare (jika pakai tunnel route dns)"
echo "      → Tambah sejahterarayagrup.com di dash.cloudflare.com"
echo "      → Ganti nameserver di Hostinger"
echo ""
echo "  Fix otomatis: bash deploy/fix-all.sh"
echo ""
