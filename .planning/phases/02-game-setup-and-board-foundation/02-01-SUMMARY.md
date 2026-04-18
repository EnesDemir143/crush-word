---
phase: 02-game-setup-and-board-foundation
plan: 01
subsystem: game-setup
tags: [flutter, setup, config, routing, navigation, widget-test]
requires:
  - phase: 01.1-requirements-architecture-and-persistence-eval-gate
    provides: eval matrix, manual gate contract, config boundary
provides:
  - Real new-game setup flow from home
  - Canonical JSON-backed setup rules
  - Two-step grid then move-count flow
  - Structured session bootstrap payload
affects: [home, routing, game-setup, config, testing]
tech-stack:
  added: []
  patterns:
    [
      canonical JSON config plus typed loader,
      two-step constrained setup flow,
      feature-owned route builders and home menu metadata,
    ]
key-files:
  created:
    [
      .planning/phases/02-game-setup-and-board-foundation/02-01-SUMMARY.md,
      assets/config/game_rules.json,
      lib/src/core/config/game_rules_config.dart,
      lib/src/core/config/game_rules_loader.dart,
      lib/src/app/app_routes.dart,
      lib/src/features/game_setup/game_setup_controller.dart,
      lib/src/features/game_setup/game_setup_routes.dart,
      lib/src/features/game_setup/new_game_screen.dart,
      lib/src/features/home/home_menu_destinations.dart,
      lib/src/features/market/market_routes.dart,
      lib/src/features/score_history/score_history_routes.dart,
      test/features/game_setup/new_game_screen_test.dart,
    ]
  modified:
    [
      .planning/ROADMAP.md,
      .planning/STATE.md,
      lib/src/app/app_router.dart,
      lib/src/app/word_crush_app.dart,
      lib/src/core/models/game_config.dart,
      lib/src/core/models/game_difficulty.dart,
      lib/src/features/home/home_screen.dart,
      lib/src/features/onboarding/username_gate.dart,
      pubspec.yaml,
    ]
key-decisions:
  - "Grid secimi ilk adimda, hamle secimi ise ikinci ekranda bagimsiz 15/20/25 paketleri olarak sunuldu."
  - "Zorluk-grid mapping ve move paketleri `assets/config/game_rules.json` icinde canonical source olarak toplandi."
  - "Routing buyudukce `AppRouter` sisin diye game setup, market ve score history route builder'lari feature dosyalarina tasindi."
  - "Home menu metadata'si router'dan ayrilip home feature icine alindi."
patterns-established:
  - "GameSetupController setup state'ini ve step gecislerini tek noktada tutar."
  - "GameSetupRoutes build katmani setup/session navigation ownership'ini feature seviyesinde toplar."
  - "HomeScreen artik menu metadata icin routing katmanina bagimli degildir."
requirements-completed: [SETUP-01, SETUP-02, SETUP-03]
completed: 2026-04-18
---

# Phase 02-01 Summary

**Yeni oyun akisi gercek setup ekranina donustu; canonical config, session bootstrap ve route ownership temizligi ayni planda tamamlandi**

## Accomplishments

- Home ekranindaki `Yeni Oyun` artik placeholder yerine gercek kurulum akisina baglandi.
- Setup kurallari `assets/config/game_rules.json` uzerinden okunur hale getirildi; widget sabitleri ve daginik mapping kaldirildi.
- Akis iki adima ayrildi: once grid secimi, sonra bagimsiz hamle secim ekrani.
- Oyun baslangici `GameConfig` ile structured payload olarak bootstrap ekranina tasinmaya baslandi.
- `AppRouter` inceltilip feature-owned route builder yapisina gecildi; home menu metadata'si ayri dosyaya tasindi.

## Verification

- `flutter analyze`
- `flutter test test/features/game_setup/new_game_screen_test.dart`
- `flutter test`

## Manual Gate

- Kullanici `Yeni Oyun -> grid secimi -> bagimsiz hamle secimi -> oyun baslangic ekranı` akisinin dogru oldugunu onayladi.
- Kullanici, Phase 02-01 icin canonical yorum olarak grid seciminin ilk adimda sabit kalmasini ve ikinci ekranda `Kolay 25`, `Orta 20`, `Zor 15` hamle paketlerinin bagimsiz sunulmasini kabul etti.

## Files Created/Modified

- `assets/config/game_rules.json` - Grid secenekleri ve bagimsiz move paketleri icin canonical setup source.
- `lib/src/core/config/game_rules_config.dart` - Typed setup config modelleri.
- `lib/src/core/config/game_rules_loader.dart` - JSON config yukleyicisi.
- `lib/src/features/game_setup/game_setup_controller.dart` - Step state ve setup secim mantigi.
- `lib/src/features/game_setup/new_game_screen.dart` - Iki adimli setup UI ve session bootstrap ekranı.
- `lib/src/features/game_setup/game_setup_routes.dart` - Setup ve session route ownership'i.
- `lib/src/app/app_routes.dart` - Shared route sabitleri.
- `lib/src/app/app_router.dart` - Feature route builder'lara delegasyon yapan ince router.
- `lib/src/features/home/home_menu_destinations.dart` - Home menu metadata kaynagi.
- `lib/src/features/home/home_screen.dart` - Home menu metadata bagimliligi temizlendi.
- `test/features/game_setup/new_game_screen_test.dart` - Setup step ve session payload davranisi dogrulandi.

## Deviations from Plan

- Ilk implementasyonda move secimi difficulty'e bagli kilitliydi; manuel gate sirasinda kullanici yorumu baz alinarak ikinci adim bagimsiz move paketleriyle revize edildi.
- Routing ve home menu ownership temizligi ayni plan icinde tamamlandi; bu refactor davranisi degistirmeden sonraki planlari sadeleştirdi.

## Next Phase Readiness

- `02-02` artik weighted board generator'u `GameConfig` ustunden guvenilir oturum girdisi ile insa edebilir.
- Setup, routing ve menu ownership sinirlari netlestigi icin board/render planlari daha dusuk riskle ilerleyebilir.

---
*Phase: 02-game-setup-and-board-foundation*
*Completed: 2026-04-18*
