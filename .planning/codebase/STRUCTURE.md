# Codebase Structure

**Analysis Date:** 2026-04-18

## Directory Layout

```
crush_word/
├── .agent/           # Kaynak dokumandan turetilen proje kurallari
├── android/          # Flutter Android runner dosyalari
├── assets/           # Sozluk ve gelecekteki runtime config asset'leri
├── docs/             # Orijinal proje PDF'i ve markdown donusumu
├── ios/              # Flutter iOS runner dosyalari
├── lib/              # Dart uygulama kodu (`main.dart` + `lib/src/`)
├── linux/            # Generated desktop scaffold
├── macos/            # Generated desktop scaffold
├── test/             # Ozellestirilmis unit/widget testleri
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

**assets/**
- Purpose: Paketlenmis uygulama verileri
- Contains: Sozluk dosyasi, ileride `assets/config/game_rules.json`
- Key files: `assets/dictionary/tr_words.txt`, `assets/config/game_rules.json`

**docs/**
- Purpose: Orijinal proje belgesi ve onun markdown donusumu
- Contains: PDF, auto-extracted markdown, ilgili image'lar
- Key files: `docs/Yazlab 2- Proje 2.pdf`, `docs/yazlab_2_2/.../Yazlab 2- Proje 2.md`

**lib/**
- Purpose: Uygulama kaynak kodu
- Contains: `main.dart`, `lib/src/app/`, `lib/src/core/`, `lib/src/features/`
- Key files: `lib/main.dart`, `lib/src/app/word_crush_app.dart`

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
- `assets/config/game_rules.json` - Donmus runtime config asset hedefi

**Testing:**
- `test/app/`, `test/core/`, `test/features/` - Faz bazli test alanlari

**Documentation:**
- `docs/Yazlab 2- Proje 2.pdf` - Birincil kaynak
- `.agent/rules/README.md` - Zorunlu maddelerin ayristirilmis ozeti

## Naming Conventions

**Current state:**
- Flutter scaffold + feature-first dizin yapisi birlikte bulunuyor
- `snake_case.dart` dosyalari ve `lib/src/...` ayrimi kullaniliyor

**Recommended for upcoming work:**
- `snake_case.dart` dosya isimleri
- `PascalCase` widget/class isimleri
- Feature-first klasorleme (`features/game`, `features/market`, vb.)
- Runtime config kodu `lib/src/core/config/` altina
- Gameplay kurallari `lib/src/core/gameplay/` altina
- SQLite adapterlari `lib/src/core/persistence/sqlite/` altina
- Repository facade'lari `lib/src/core/repositories/` altina

## Frozen Future Core Layout

```text
assets/
  config/
    game_rules.json

lib/src/core/
  config/
  gameplay/
  persistence/
    sqlite/
  repositories/
    wallet_repository.dart
    session_checkpoint_repository.dart
```

Bu layout, downstream implementasyonlarda aranacak canonical yerlesimdir:
- `core/gameplay` -> rule engine, modeller, board/service mantigi
- `core/config` -> `game_rules.json` loader/validator katmani
- `core/persistence/sqlite` -> `sqflite` tablo, migration ve mapper detaylari
- `wallet_repository` ve `session_checkpoint_repository` -> uygulamanin domain-facing persistence sinirlari

## Where to Add New Code

**New feature:**
- Primary code: `lib/src/features/`
- Shared models/services: `lib/src/core/`
- Runtime config: `lib/src/core/config/`
- Gameplay logic: `lib/src/core/gameplay/`
- SQLite adapters: `lib/src/core/persistence/sqlite/`
- Repository facades: `lib/src/core/repositories/`
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
*Structure analysis: 2026-04-18*
*Update when directory structure changes*
