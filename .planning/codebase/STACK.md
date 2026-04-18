# Technology Stack

**Analysis Date:** 2026-04-09

## Languages

**Primary:**
- Dart 3.11.x - Tum uygulama kodu

**Secondary:**
- Kotlin / Swift / C++ generated runner files - Platform scaffold tarafinda Flutter tarafindan uretilen dosyalar
- Markdown - Gereksinim, kural ve planlama dokumantasyonu

## Runtime

**Environment:**
- Flutter SDK - Mobil UI ve paketleme
- Dart runtime - Is mantigi ve testler

**Package Manager:**
- Pub
- Lockfile: `pubspec.lock` mevcut

## Frameworks

**Core:**
- Flutter - Tek UI framework'u
- Material - Varsayilan tasarim sistemi

**Testing:**
- `flutter_test` - Unit/widget testleri icin mevcut

**Build/Dev:**
- Flutter toolchain - analyze, test, build, run
- `flutter_lints` - Varsayilan lint paketi

## Key Dependencies

**Critical:**
- `flutter` - UI ve runtime
- `cupertino_icons` - Varsayilan ikon paketi
- `shared_preferences` - Profil ve hafif ayarlar icin mevcut yerel key-value depolama

**Infrastructure:**
- Dis servis bagimliligi bulunmuyor

**Planned Local Persistence:**
- `sqflite` - Skor gecmisi, altin ve joker envanteri icin planlanan SQLite katmani

## Configuration

**Environment:**
- Harici `.env` veya API anahtari gereksinimi yok

**Build:**
- `pubspec.yaml`
- `analysis_options.yaml`
- Platform klasorlerindeki Flutter scaffold dosyalari

## Platform Requirements

**Development:**
- Flutter kurulu macOS/Windows/Linux ortami
- Android emulatoru veya iOS simulatoru/cihaz

**Production:**
- Hedef mobil calisma zamani Android veya iOS
- Web ve masaustu teslim kapsaminda degil

---
*Stack analysis: 2026-04-09*
*Update after major dependency changes*
