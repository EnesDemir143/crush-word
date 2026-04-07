---
phase: 01-foundation-and-shell
plan: 03
subsystem: core
tags: [dictionary, offline-validation, models, serialization]
requires:
  - phase: 01-foundation-and-shell
    provides: app shell, persisted profile flow and home menu
provides:
  - Packaged offline Turkish dictionary asset
  - Dictionary repository with Turkish normalization and cached lookup
  - Shared gameplay models for difficulty, config and result records
  - Core test coverage for dictionary loading and normalization
affects: [assets, validation, gameplay, score-history, persistence]
tech-stack:
  added: []
  patterns:
    [
      packaged asset-backed repository,
      canonical difficulty-to-grid mapping,
      serialization-friendly shared domain models,
    ]
key-files:
  created:
    [
      assets/dictionary/README.md,
      assets/dictionary/tr_words.txt,
      lib/src/core/repositories/dictionary_repository.dart,
      lib/src/core/models/game_difficulty.dart,
      lib/src/core/models/game_config.dart,
      lib/src/core/models/game_result.dart,
      test/core/dictionary_repository_test.dart,
    ]
  modified: [.gitignore, pubspec.yaml]
key-decisions:
  - "Sozluk, uygulama icinde `assets/dictionary/tr_words.txt` olarak paketlendi ve network bagimliligi kaldirildi."
  - "Zorluk kurallari `GameDifficulty` uzerinde merkezi tutuldu; `GameConfig` bu mapping'i canonical veri sekline donusturuyor."
  - "Skor gecmisi ihtiyaclari icin `GameResult` tarih, sure, skor, kelime sayisi ve en uzun kelime alanlariyla kaliciliga hazir tasarlandi."
patterns-established:
  - "DictionaryRepository kelime listesini bir kez yukler, normalize eder ve sonraki lookup'larda cache kullanir."
  - "Gameplay ve history akislarinin ortak veri yapilari core/models altinda tek kaynak olarak tanimlandi."
requirements-completed: [PLAT-02]
duration: 35min
completed: 2026-04-07
---

# Phase 1: Foundation and Shell Summary

**Offline Turkce sozluk hatti ve sonraki fazlarin paylasacagi temel oyun modelleri eklendi**

## Performance

- **Duration:** 35 min
- **Completed:** 2026-04-07T12:25:52+03:00
- **Tasks:** 2
- **Files modified:** 9

## Accomplishments

- Hunspell kaynagindan uretilen `tr_words.txt` asset'i uygulamaya baglandi ve `DictionaryRepository` ile offline lookup kullanima hazir hale geldi.
- Turkce buyuk/kucuk harf donusumu ve noktalama temizligi tek noktada normalize edildi.
- `GameDifficulty`, `GameConfig` ve `GameResult` modelleri sonraki setup, gameplay ve score-history fazlarinin kullanacagi ortak contract olarak eklendi.

## Verification

- `flutter analyze`
- `flutter test test/core/dictionary_repository_test.dart`

## Task Commits

- `feat(core): add offline dictionary asset pipeline`
- `feat(core): add shared gameplay domain models`

## Files Created/Modified

- `assets/dictionary/tr_words.txt` - Paketlenmis offline Turkce kelime listesi.
- `assets/dictionary/README.md` - Kaynak ve paketleme notlari.
- `lib/src/core/repositories/dictionary_repository.dart` - Cache'li yukleme, lookup ve Turkce normalizasyon.
- `lib/src/core/models/game_difficulty.dart` - 6x6/8x8/10x10 ve 15/20/25 mapping'i.
- `lib/src/core/models/game_config.dart` - Setup secimini canonical ve serialize edilebilir sekilde tasiyan model.
- `lib/src/core/models/game_result.dart` - Skor gecmisi icin gereken session sonuc modeli.
- `test/core/dictionary_repository_test.dart` - Asset yukleme ve normalizasyon smoke coverage'i.
- `pubspec.yaml` - Dictionary asset tanimi.
- `.gitignore` - Ham Hunspell import klasorunu takip disinda tuttu.

## Deviations from Plan

None - plan executed as intended.

## Next Phase Readiness

- Faz 2 artik `GameConfig` uzerinden setup secimini guvenilir sekilde game ekranina tasiyabilir.
- Faz 3 kelime dogrulama akisi `DictionaryRepository` ile local lookup kullanabilir.
- Faz 5 skor gecmisi ve agregasyonlar `GameResult` ustune kurulabilir.

---
*Phase: 01-foundation-and-shell*
*Completed: 2026-04-07*
