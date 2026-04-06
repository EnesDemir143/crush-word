# External Integrations

**Analysis Date:** 2026-04-07

## APIs & External Services

Bu kod tabaninda halihazirda harici API veya servis entegrasyonu yok.

## Data Storage

**Current state:**
- Kalici veri katmani henuz uygulanmamis

**Planned direction for this project:**
- Kullanici adi, skor gecmisi, altin ve joker envanteri yerel depolamada tutulacak
- Kelime dogrulama, paketlenmis bir yerel sozluk asset'i ile yapilacak

## Authentication & Identity

- Harici auth sistemi yok
- Kimlik modeli tek cihaz uzerindeki kullanici adi ile sinirli olacak

## Monitoring & Observability

- Sentry, analytics veya cloud log servisi yok
- Hata ayiklama icin Flutter debug loglari yeterli

## CI/CD & Deployment

- GitHub Actions, Fastlane veya benzeri otomasyon henuz yok
- Derleme ve sunum yerel makine/IDE uzerinden yapilacak

## Environment Configuration

**Development:**
- Harici secret gerekmiyor
- Sozluk dosyasi ve oyun sabitleri repo icinde tutulacak

**Production / Delivery:**
- Sunum icin emulator veya fiziksel cihaz gerekir
- Teslim icin PDF + LaTeX kaynaklari gerekir

## Webhooks & Callbacks

- Yok

---
*Integration audit: 2026-04-07*
*Update when adding/removing external services*
