---
phase: 03-core-gameplay-and-session-results
plan: 01
subsystem: word-validation
tags: [flutter, word-validator, dictionary, turkish-casing, selection-finalization, move-consumption, feedback-state]
requires:
  - phase: 02-game-setup-and-board-foundation
    provides: drag selection, board UI, game controller, session models
  - phase: 02.1-initial-board-solvability-gate
    provides: trie-backed board analyzer, dictionary repository
provides:
  - Pure WordValidator service with explicit result reasons (tooShort, notInDictionary, valid)
  - Selection finalization logic in GameController.endSelection()
  - Move consumption on both valid and invalid attempts (GRID-06)
  - Lightweight invalid-feedback state without dialog/popup
  - Inline _InvalidFeedbackBanner UI component
affects: [game-controller, game-screen, word-validator, letter-grid]
tech-stack:
  added: []
  patterns:
    [
      Pure validator service with DI for testability,
      Transient feedback state consumed on next interaction,
      Concurrent finalization guard (_isFinalizing),
      Fire-and-forget async callback wrapping in UI,
    ]
key-files:
  created:
    [
      lib/src/core/gameplay/services/word_validator.dart,
      test/core/word_validator_test.dart,
      test/features/game/selection_finalize_test.dart,
      .planning/phases/03-core-gameplay-and-session-results/03-01-SUMMARY.md,
    ]
  modified:
    [
      lib/src/features/game/game_controller.dart,
      lib/src/features/game/game_screen.dart,
      test/features/game/drag_selection_test.dart,
      .planning/STATE.md,
    ]
key-decisions:
  - "WordValidator pure service olarak tasarlandi; board state'e dokunmuyor, sadece validation result donduruyor."
  - "InvalidAttemptFeedback transient state olarak tutulup startSelection'da otomatik temizleniyor; dialog/popup açılmıyor."
  - "endSelection() artık async; LetterGrid callback'i unawaited() wrapper ile fire-and-forget olarak baglandi."
  - "_isFinalizing guard ile concurrent finalization onleniyor."
  - "Hem valid hem invalid attempt 1 hamle dusunyor (GRID-06 uyumu)."
patterns-established:
  - "WordValidator inject edilebilir; test'lerde in-memory DictionaryRepository ile mock'lanıyor."
  - "GameController.lastInvalidFeedback ile UI feedback state yonetimi — no popup, inline banner."
  - "Board letters invalid attempt sonrasinda mutate edilmiyor; sadece selection ve moves guncelleniyor."
requirements-completed: [GRID-04, GRID-05, GRID-06]
completed: 2026-04-18
---

# Phase 03-01 Summary

**Kelime doğrulama ve seçim sonlandırma akışı tamamlandı; geçersiz/geçerli her deneme 1 hamle düşürüyor**

## Accomplishments

- `WordValidator` servisi oluşturuldu: seçim yolundaki harfleri Türkçe casing normalization ile kelimeye dönüştürüp sözlükte kontrol ediyor.
- Validation sonucu üç ayrı reason enum'u ile açık: `tooShort`, `notInDictionary`, `valid`.
- `GameController.endSelection()` artık parmak kaldırılınca çalışıyor: kelimeyi doğrulayıp hem geçerli hem geçersiz durumda 1 hamle düşürüyor.
- Geçersiz denemede board harfleri değişmiyor, yalnızca seçim temizleniyor.
- `_InvalidFeedbackBanner` inline bileşeni eklendi — dialog/popup yerine board altında hafif kırmızı banner gösteriyor.
- Feedback state yeni seçim başladığında otomatik temizleniyor.
- 11 word validator testi + 10 selection finalize testi = 21 yeni test eklendi.
- Mevcut drag_selection_test async endSelection'a uygun güncellendi.

## Verification

- `flutter analyze` — No issues found
- `flutter test test/core/word_validator_test.dart` — 11/11 passed
- `flutter test test/features/game/selection_finalize_test.dart` — 10/10 passed
- `flutter test` — 52/52 passed (full suite, zero regressions)
- MANUAL GATE: Geçersiz kelimede seçim temizleniyor ve 1 hamle düşümü gerçekleşiyor. Kullanıcı onayı bekleniyor.

## Files Created/Modified

- `lib/src/core/gameplay/services/word_validator.dart` — Pure word validation servisi, Türkçe casing normalization, explicit result reasons.
- `lib/src/features/game/game_controller.dart` — endSelection() artık async, WordValidator ile doğrulama yapıyor, hamle düşürüyor, feedback state yönetiyor.
- `lib/src/features/game/game_screen.dart` — _InvalidFeedbackBanner eklendi, word_validator import'u eklendi, async endSelection wrapping.
- `test/core/word_validator_test.dart` — 11 test: tooShort, notInDictionary, valid, Türkçe İ/I/Ş/Ü/Ö/Ç normalization coverage.
- `test/features/game/selection_finalize_test.dart` — 10 test: move decrement, board immutability, selection clearing, feedback state, edge cases.
- `test/features/game/drag_selection_test.dart` — Async endSelection uyumuna güncellendi.

## Deviations from Plan

- Plan `endSelection`'ın senkron olmasını ima ediyordu ancak `DictionaryRepository.contains()` async olduğundan `endSelection()` de async yapıldı. Bu LetterGrid'in `VoidCallback?` tipiyle uyumlu kalmak için `unawaited()` wrapper ile bağlandı.

## Next Phase Readiness

- `03-02` artık valid word sonrasında scoring, gravity ve refill pipeline'ını ekleyebilir. `endSelection()` valid branch'inde board mutasyonu hook'u hazır.
- `03-03` session result persistence'ı ekleyebilir.

---
*Phase: 03-core-gameplay-and-session-results*
*Completed: 2026-04-18*
