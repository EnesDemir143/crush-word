---
phase: 03-core-gameplay-and-session-results
plan: 02
subsystem: scoring-and-board-resolution
tags: [flutter, scoring-engine, board-resolver, gravity, refill, letter-scores, turkish]
requires:
  - phase: 03-core-gameplay-and-session-results
    plan: 01
    provides: word validation, selection finalization, move consumption
provides:
  - Canonical letter-score table in game_rules.json (PDF-verified)
  - ScoringConfig model with case-insensitive lookups
  - Pure ScoringEngine service with per-letter breakdown
  - Pure BoardResolver service (clear → gravity → refill pipeline)
  - GameController wiring — valid words update score + board in one pass
affects: [game-controller, game-rules-config, game-rules-json, board-generator]
tech-stack:
  added: []
  patterns:
    [
      Pure scoring engine with DI for testability,
      Pure board resolver with deterministic refill via injected generator,
      Config-driven letter scores — single canonical source,
      Column-major gravity collapse with top-down refill,
      Cached rules config for post-load reuse,
    ]
key-files:
  created:
    [
      lib/src/core/gameplay/services/scoring_engine.dart,
      lib/src/core/gameplay/services/board_resolver.dart,
      test/core/scoring_engine_test.dart,
      test/core/board_resolver_test.dart,
      .planning/phases/03-core-gameplay-and-session-results/03-02-SUMMARY.md,
    ]
  modified:
    [
      assets/config/game_rules.json,
      lib/src/core/config/game_rules_config.dart,
      lib/src/core/gameplay/services/board_generator.dart,
      lib/src/features/game/game_controller.dart,
      .planning/STATE.md,
    ]
key-decisions:
  - "Harf puan tablosu game_rules.json'da tek canonical kaynak olarak tutuldu; kod içinde duplicate yok."
  - "ScoringConfig uppercase normalise ediyor; lookup case-insensitive."
  - "BoardResolver column-major yapıda gravity uygulayıp, üstten dolduruyor."
  - "BoardGenerator._pickWeightedLetter → pickWeightedLetter olarak public yapıldı (refill hook)."
  - "GameController.endSelection() valid branch: scoring → board resolution → session update tek copyWith'te."
  - "GameRulesConfig load sırasında cachedRules olarak saklanıyor; refill generator rules buradan okuyor."
patterns-established:
  - "ScoringEngine pure service; ScoringConfig inject edilerek test'lerde canonical tablo kullanılıyor."
  - "BoardResolver pure service; BoardGenerator inject edilerek deterministic refill testi yapılabiliyor."
  - "_FixedRandom test helper pattern — cycling through a list of values for deterministic random."
requirements-completed: [GRID-07, SCORE-01]
completed: 2026-04-18
---

# Phase 03-02 Summary

**Puanlama motoru ve board resolution pipeline'ı tamamlandı; geçerli kelimeler skor güncelliyor ve tahtayı yeniden dolduruyor**

## Accomplishments

- PDF'den doğrulanmış 29 harflik Türkçe puan tablosu `assets/config/game_rules.json`'a `scoring.letterScores` olarak eklendi — tek canonical kaynak.
- `ScoringConfig` model sınıfı oluşturuldu: uppercase normalisation, `scoreOf()` ile case-insensitive lookup, `fromJson` parser.
- `GameRulesConfig` artık opsiyonel `scoring` alanını destekliyor; eski config'ler hâlâ çalışıyor.
- `ScoringEngine` pure servisi oluşturuldu: kelime → per-letter breakdown + total score.
- `BoardResolver` pure servisi oluşturuldu: clear → gravity (column-major) → refill (top-down) pipeline.
- `BoardGenerator.pickWeightedLetter` public yapıldı — refill sırasında aynı ağırlıklı harf üretim mantığı kullanılıyor.
- `GameController.endSelection()` valid branch artık: (1) ScoringEngine ile puan hesapla, (2) BoardResolver ile tahtayı çöz, (3) tek `copyWith` ile session güncelle.
- `GameRulesConfig` load sırasında `_cachedRules` olarak saklanıyor; refill için tekrar disk okuma yok.
- 18 scoring engine testi + 10 board resolver testi = 28 yeni test eklendi.
- Full test suite: 80/80 passed, zero regressions.

## Verification

- `flutter analyze` — No issues found
- `flutter test test/core/scoring_engine_test.dart` — 18/18 passed
- `flutter test test/core/board_resolver_test.dart` — 10/10 passed  
- `flutter test` — 80/80 passed (full suite, zero regressions)
- MANUAL GATE: Geçerli kelime sonrası skor artışı ve board refill davranışı görünür; kullanıcı onayı bekleniyor.
- MANUAL GATE: Canonical harf puan tablosu kaynak dokümandaki tabloyla birebir karşılaştırılır; kullanıcı onayı bekleniyor.

## Files Created/Modified

- `assets/config/game_rules.json` — `scoring.letterScores` eklendi (29 harf, PDF-confirmed).
- `lib/src/core/config/game_rules_config.dart` — `ScoringConfig` sınıfı ve `GameRulesConfig.scoring` alanı eklendi.
- `lib/src/core/gameplay/services/scoring_engine.dart` — Pure scoring engine, `ScoringResult` ile per-letter breakdown.
- `lib/src/core/gameplay/services/board_resolver.dart` — Pure board resolver, `BoardResolveResult` ile clear/gravity/refill.
- `lib/src/core/gameplay/services/board_generator.dart` — `_pickWeightedLetter` → `pickWeightedLetter` (public).
- `lib/src/features/game/game_controller.dart` — Scoring engine + board resolver import/DI/wiring, `_cachedRules`, `_scoringEngine`, `_boardResolver`.
- `test/core/scoring_engine_test.dart` — 18 test: soru=7, Turkish-specific letters, case insensitivity, config parsing.
- `test/core/board_resolver_test.dart` — 10 test: cell removal, gravity, refill, multi-column, coordinate validity, edge cases.

## Deviations from Plan

- Yok. Plan tam olarak uygulandı.

## Next Phase Readiness

- `03-03` session result persistence'ı ekleyebilir; session.score artık doğru güncelleniyor.
- Phase 4 combo puanlama ve özel güç dogurma bu pipeline'ın üstüne inşa edilebilir.

---
*Phase: 03-core-gameplay-and-session-results*
*Completed: 2026-04-18*
