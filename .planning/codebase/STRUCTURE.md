# Codebase Structure

**Analysis Date:** 2026-04-07

## Directory Layout

```
crush_word/
├── .agent/           # Kaynak dokumandan turetilen proje kurallari
├── android/          # Flutter Android runner dosyalari
├── docs/             # Orijinal proje PDF'i ve markdown donusumu
├── ios/              # Flutter iOS runner dosyalari
├── lib/              # Dart uygulama kodu
├── linux/            # Generated desktop scaffold
├── macos/            # Generated desktop scaffold
├── test/             # Varsayilan Flutter testleri
├── web/              # Generated web scaffold
├── windows/          # Generated desktop scaffold
├── pubspec.yaml      # Paket ve asset tanimlari
└── README.md         # Varsayilan repo README'si
```

## Directory Purposes

**.agent/**
- Purpose: Kaynak gereksinimlerden turetilen zorunlu kural dosyalari
- Contains: Kategori bazli markdown kurallari
- Key files: `.agent/rules/*.md`

**docs/**
- Purpose: Orijinal proje belgesi ve onun markdown donusumu
- Contains: PDF, auto-extracted markdown, ilgili image'lar
- Key files: `docs/Yazlab 2- Proje 2.pdf`, `docs/yazlab_2_2/.../Yazlab 2- Proje 2.md`

**lib/**
- Purpose: Uygulama kaynak kodu
- Contains: Su anda yalnizca `main.dart`
- Key files: `lib/main.dart`

**test/**
- Purpose: Otomatik testler
- Contains: Varsayilan starter widget testi
- Key files: `test/widget_test.dart`

**build/**
- Purpose: Derleme ciktilari
- Contains: Flutter build artifact'lari
- Committed: Bu calisma alaninda mevcut; hedefte versiyon kontrolunde tutulmamali

## Key File Locations

**Entry Points:**
- `lib/main.dart` - Flutter app entry point

**Configuration:**
- `pubspec.yaml` - Paket/asset tanimlari
- `analysis_options.yaml` - Lint kurallari

**Testing:**
- `test/widget_test.dart` - Starter test

**Documentation:**
- `docs/Yazlab 2- Proje 2.pdf` - Birincil kaynak
- `.agent/rules/README.md` - Zorunlu maddelerin ayristirilmis ozeti

## Naming Conventions

**Current state:**
- Flutter scaffold isimlendirmesi agirlikli
- Belirgin feature dizin yapisi henuz yok

**Recommended for upcoming work:**
- `snake_case.dart` dosya isimleri
- `PascalCase` widget/class isimleri
- Feature-first klasorleme (`features/game`, `features/market`, vb.)

## Where to Add New Code

**New feature:**
- Primary code: `lib/src/features/`
- Shared models/services: `lib/src/core/`
- Tests: `test/` ve gerekirse `integration_test/`

**Documentation / planning:**
- Planning artifacts: `.planning/`
- Delivery docs: `docs/` veya `report/`

## Special Directories

**build/**
- Purpose: Generated artifacts
- Source: Flutter build process
- Committed: Ideally hayir

**web/, macos/, windows/, linux/**
- Purpose: Cross-platform scaffold
- Source: Flutter create
- Note: Proje teslim hedefi mobil olsa da bu klasorler scaffold olarak duruyor

---
*Structure analysis: 2026-04-07*
*Update when directory structure changes*
