---
phase: 05-market-and-score-history
plan: 01
subsystem: market-catalog-and-economy-foundation
tags: [flutter, market, sqflite, economy, ui]
requires:
  - phase: 03-core-gameplay-and-session-results
    plan: 03
    provides: shared sqflite app database and persisted game results baseline
provides:
  - canonical market catalog in game_rules.json
  - sqflite-backed wallet balance and joker inventory repositories
  - interactive market UI with live gold, detail dialog and purchase baseline
  - focused widget coverage for market rendering and purchase feedback
affects: [market, economy, configuration, persistence, ui]
tech-stack:
  added: []
  patterns:
    [
      canonical config-backed joker catalog,
      repository-backed SQLite wallet and inventory persistence,
      controller-driven market state,
      fake repository widget tests for UI flows,
    ]
key-files:
  created:
    [
      lib/src/core/models/joker_inventory.dart,
      lib/src/core/repositories/wallet_repository.dart,
      lib/src/core/repositories/joker_inventory_repository.dart,
      lib/src/features/market/market_controller.dart,
      lib/src/features/market/market_screen.dart,
      test/features/market/market_screen_test.dart,
      .planning/phases/05-market-and-score-history/05-01-SUMMARY.md,
    ]
  modified:
    [
      assets/config/game_rules.json,
      lib/src/core/config/game_rules_config.dart,
      lib/src/core/persistence/sqlite/app_database.dart,
      lib/src/features/market/market_routes.dart,
      .planning/ROADMAP.md,
      .planning/STATE.md,
      .planning/REQUIREMENTS.md,
    ]
key-decisions:
  - "Joker ad, fiyat ve aciklama verisi tek canonical source olarak `assets/config/game_rules.json` icine yazildi."
  - "Altin bakiyesi ve joker stoklari mevcut `word_crush.db` icine yeni tablolarla eklendi; hafif ayar storage'ina tasinmadi."
  - "Kullanici geri bildirimiyle market kartlari sade tutuldu; joker detaylari ve satin alma aksiyonu dialog icine tasindi."
  - "Market satin alma baseline'i UI seviyesinde aktif, ancak gameplay joker effect owner'ligi Phase `05-02`'de kalir."
patterns-established:
  - "MarketScreen -> MarketController -> WalletRepository/JokerInventoryRepository zinciri katalog, UI ve persistence sorumluluklarini ayirir."
  - "Widget testleri fake repository'lerle SQLite bagimliligindan ayrik tutulur."
requirements-completed: [ECON-01, MKT-01, MKT-02]
completed: 2026-04-19
---

# Phase 05-01 Summary

**Market katalogu, ekonomi persistensi ve kullanici onayli market UI temeli tamamlandi**

## Accomplishments

- `assets/config/game_rules.json` icine PDF ile birebir uyumlu 6 jokerlik
  canonical katalog eklendi; market artik ad, fiyat ve aciklama verisini tek
  kaynaktan okuyor.
- `GameRulesConfig` market bolumunu parse edecek sekilde genisletildi; joker
  katalogu runtime'da typed model olarak okunuyor.
- `AppDatabase` schema version `2`'ye tasindi; `wallet_balance` ve
  `joker_inventory` tablolari paylasilan SQLite veritabanina eklendi.
- `WalletRepository` ve `JokerInventoryRepository`, baslangic altini `9999`
  olacak sekilde yerel ekonomi state'ini kalici hale getirdi.
- Placeholder market route kaldirildi; yerine gercek `MarketScreen` ve
  `MarketController` baglandi.
- Market UI, kullanici geri bildirimine gore sadeleştirildi: kartlarda isim,
  maliyet, stok ve kisa aciklama gorunuyor; joker detaylari ve `Satın Al`
  aksiyonu dialog icinde sunuluyor.
- Popup akisi joker gorseli, maliyet, stok, aciklama ve kullanim seklini
  gosteriyor; satin alma sonrasi altin ve stok ayni ekranda aninda guncelleniyor.
- Hedef widget testi, katalog gorunurlugunu, detay popup'ini ve satin alma geri
  bildirimini kapsayacak sekilde eklendi.

## Verification

- `flutter analyze` — No issues found
- `flutter test test/features/market/market_screen_test.dart -r expanded` —
  4/4 passed
- `python3 -c "from graphify.watch import _rebuild_code; from pathlib import Path; _rebuild_code(Path('.'))"` —
  graph rebuilt successfully
- MANUAL GATE passed: `assets/config/game_rules.json` joker adlari, fiyatlari ve
  aciklamalari kaynak dokumanla dogrulandi
- MANUAL GATE passed: market ekrani guncel altini, tum zorunlu jokerleri ve
  kart seviyesinde maliyet/aciklama bilgilerini gosteriyor

## Files Created/Modified

- `assets/config/game_rules.json` — canonical market catalog ve test altini
  baseline'i.
- `lib/src/core/config/game_rules_config.dart` — market config modelleri.
- `lib/src/core/persistence/sqlite/app_database.dart` — wallet ve inventory
  tablolarinin schema bootstrap'i.
- `lib/src/core/models/joker_inventory.dart` — inventory domain modeli.
- `lib/src/core/repositories/wallet_repository.dart` — altin bakiyesi load/save.
- `lib/src/core/repositories/joker_inventory_repository.dart` — joker stok
  load/save.
- `lib/src/features/market/market_controller.dart` — market load ve satin alma
  state orchestration'i.
- `lib/src/features/market/market_screen.dart` — guncel market UI ve detail
  dialog akisi.
- `lib/src/features/market/market_routes.dart` — gercek market ekranina route.
- `test/features/market/market_screen_test.dart` — market UI ve satin alma
  coverage'i.

## Next Phase Readiness

- Phase `05-02`, mevcut joker envanteri ve canonical katalogu dogrudan kullanip
  oyun ekranindaki secici/kullanim akisini baglayabilir.
- Buna ragmen roadmap sirasi acisindan bir sonraki zorunlu owner hala Phase
  `04-01`'dir; post-move solvability continuity ve visible count tamamlanmadan
  ileri joker effect davranislari tam kapanmis sayilmayacak.
