# Panduan Detail: Cloudflare + Hostinger
## Domain: seraya-group.online

---

## Gambaran Arsitektur

```
Pengunjung
    ↓
seraya-group.online (DNS)
    ↓
Cloudflare Tunnel (web-pi)
    ↓
Raspberry Pi → localhost:3000 (Website Seraya)
```

**Yang sudah berjalan di Pi Anda:**
- Website Seraya → port `3000` ✅
- Site lama fid-maintenance.online → port `3001` ✅
- Tunnel `web-pi` → ID `6bed7d36-e77d-4651-94ed-24efde5485b1` ✅

---

# PILIHAN SETUP

| | Opsi A: Cloudflare DNS | Opsi B: DNS Hostinger |
|---|---|---|
| **Rekomendasi** | ✅ Disarankan | Jika tidak mau pindah NS |
| **Domain tetap di** | Hostinger (registrar) | Hostinger |
| **DNS di-manage** | Cloudflare | Hostinger hPanel |

---

# OPSI A — DNS via Cloudflare (Disarankan)

Domain **tetap di Hostinger**, DNS di-manage **Cloudflare**.

---

## A1. Daftar domain di Cloudflare

1. Buka https://dash.cloudflare.com → Login
2. Klik **Add a site** → ketik `seraya-group.online` → **Continue**
3. Pilih plan **Free** → **Continue**
4. Skip review DNS → **Continue**
5. **Catat 2 nameserver** Cloudflare, contoh:
   ```
   ada.ns.cloudflare.com
   bob.ns.cloudflare.com
   ```

---

## A2. Ubah Nameserver di Hostinger

1. Login **hPanel**: https://hpanel.hostinger.com
2. Menu **Domains** (kiri)
3. Klik domain **seraya-group.online**
4. Buka tab **DNS** atau **DNS / Nameservers**
5. Klik **Change nameservers** / **Ganti nameserver**
6. Pilih **Use custom nameservers** (bukan Hostinger default)
7. Isi nameserver dari Cloudflare:

   | Nameserver 1 | `ada.ns.cloudflare.com` *(sesuaikan)* |
   | Nameserver 2 | `bob.ns.cloudflare.com` *(sesuaikan)* |

8. Klik **Save** / **Simpan**

**Nameserver default Hostinger** (yang diganti):
```
ns1.dns-parking.com
ns2.dns-parking.com
```
atau
```
ns1.hostinger.com
ns2.hostinger.com
```

### Tunggu propagasi
- **15 menit – 24 jam** (biasanya 1–2 jam)
- Cloudflare Dashboard: status **Pending** → **Active**

### Verifikasi
```bash
nslookup -type=NS seraya-group.online
```
Harus muncul `cloudflare.com`.

---

## A3. Route DNS di Raspberry Pi

Setelah domain **Active** di Cloudflare:

```bash
cloudflared tunnel route dns web-pi seraya-group.online
cloudflared tunnel route dns web-pi www.seraya-group.online
sudo systemctl restart cloudflared
```

Output **benar**:
```
Added CNAME seraya-group.online which will route to this tunnel
```

Output **salah** (domain belum Active):
```
seraya-group.online.fid-maintenance.online is already configured
```
→ Ulangi A1–A2.

### Cek di Cloudflare Dashboard
**DNS → Records** harus ada:

| Type | Name | Content | Proxy |
|------|------|---------|-------|
| CNAME | seraya-group.online | 6bed7d36...cfargotunnel.com | Proxied ☁️ |
| CNAME | www | 6bed7d36...cfargotunnel.com | Proxied ☁️ |

---

## A4. Config tunnel di Pi

File `~/.cloudflared/config.yml`:

```yaml
tunnel: 6bed7d36-e77d-4651-94ed-24efde5485b1
credentials-file: /home/fajar/.cloudflared/6bed7d36-e77d-4651-94ed-24efde5485b1.json

ingress:
  - hostname: fid-maintenance.online
    service: http://127.0.0.1:3001

  - hostname: seraya-group.online
    service: http://127.0.0.1:3000

  - hostname: www.seraya-group.online
    service: http://127.0.0.1:3000

  - service: http_status:404
```

```bash
sudo systemctl restart cloudflared
```

---

# OPSI B — DNS Tetap di Hostinger

Tanpa pindah nameserver. Set DNS manual di hPanel.

---

## B1. Buka DNS Zone di Hostinger

1. Login https://hpanel.hostinger.com
2. **Domains** → **seraya-group.online**
3. Tab **DNS** / **DNS Zone** / **Manage DNS records**

Tampilan hPanel (kurang lebih):

```
┌──────────┬──────────┬──────────────────────────────────────┬──────┐
│ Type     │ Name     │ Points to                            │ TTL  │
├──────────┼──────────┼──────────────────────────────────────┼──────┤
│ CNAME    │ www      │ 6bed7d36...cfargotunnel.com          │ 14400│
└──────────┴──────────┴──────────────────────────────────────┴──────┘
```

---

## B2. Hapus record konflik

Hapus record lama jika ada:
- **A** record `@` → IP hosting Hostinger
- **A** record `www` → IP hosting
- **CNAME** lama untuk `www`
- **AAAA** record (opsional, bisa konflik)

---

## B3. Tambah record CNAME

Klik **Add Record** / **Tambah Record**:

### Record 1 — www (wajib)

| Field | Isi |
|-------|-----|
| **Type** | CNAME |
| **Name** | `www` |
| **Points to / Target** | `6bed7d36-e77d-4651-94ed-24efde5485b1.cfargotunnel.com` |
| **TTL** | 14400 (default) |

Klik **Add Record** / **Simpan**.

### Record 2 — root domain @

| Field | Isi |
|-------|-----|
| **Type** | CNAME |
| **Name** | `@` |
| **Points to / Target** | `6bed7d36-e77d-4651-94ed-24efde5485b1.cfargotunnel.com` |
| **TTL** | 14400 |

> Hostinger kadang mendukung CNAME di `@`. Jika ditolak, lihat B4.

---

## B4. Jika CNAME @ tidak bisa

### Solusi 1 — Pakai www saja
Akses website via: `https://www.seraya-group.online`

### Solusi 2 — Redirect di Hostinger
1. hPanel → **Domains** → **Redirects**
2. Tambah redirect:
   - **From:** `seraya-group.online`
   - **To:** `https://www.seraya-group.online`
   - **Type:** Permanent (301)

### Solusi 3 — Pindah ke Cloudflare (Opsi A)
Cloudflare mendukung CNAME flattening untuk root domain.

---

## B5. Config tunnel di Pi

**Jangan** jalankan `cloudflared tunnel route dns` (DNS manual di Hostinger).

Pastikan `~/.cloudflared/config.yml` sama seperti A4, lalu:

```bash
sudo systemctl restart cloudflared
```

---

## B6. Verifikasi

Tunggu **5–30 menit** setelah save DNS.

```bash
nslookup seraya-group.online
nslookup www.seraya-group.online
curl https://www.seraya-group.online/health
bash deploy/verify.sh
```

---

# PERBANDINGAN DOMAIN

| | fid-maintenance.online | seraya-group.online |
|---|---|---|
| **Registrar** | ? | Hostinger |
| **Tunnel** | web-pi (sama) | web-pi (sama) |
| **Port Pi** | 3001 | 3000 |

---

# TROUBLESHOOTING

| Error | Solusi |
|-------|--------|
| Could not resolve host | DNS belum diset / belum propagate |
| seraya-group.online.fid-maintenance.online | Domain belum ditambah ke Cloudflare (Opsi A) |
| 502 Bad Gateway | `sudo systemctl restart seraya-website` |
| 404 Cloudflare | Cek ingress di config.yml |

---

# CHECKLIST

```
[ ] curl http://127.0.0.1:3000/health → OK
[ ] config.yml ada seraya-group.online
[ ] DNS diset (Cloudflare ATAU Hostinger)
[ ] nslookup → cfargotunnel.com
[ ] https://seraya-group.online/health → OK
```

---

# SCRIPT BANTUAN

```bash
cd ~/seraya/SerayaGroup
bash deploy/setup-dns-hostinger.sh   # panduan DNS Hostinger
bash deploy/verify.sh                # cek status
```
