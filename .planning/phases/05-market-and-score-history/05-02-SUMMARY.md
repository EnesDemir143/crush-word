---
phase: 05-market-and-score-history
plan: 02
subsystem: in-game-joker-actions
tags: [flutter, market, gameplay, jokers, sqlite]
requires:
  - phase: 05-market-and-score-history
    plan: 01
    provides: wallet and joker inventory persistence plus canonical joker catalog
  - phase: 04-advanced-board-mechanics
    plan: 03
    provides: board mutation pipeline, post-move recovery and power-aware resolver
provides:
  - transaction-backed joker purchase flow
  - in-game owned-joker bar
  - live joker effect engine for all six documented jokers
  - unit/widget coverage for joker effects and joker bar rendering
affects: [market, gameplay, inventory, board-effects, ui]
tech-stack:
  added: []
  patterns:
    [
      transaction-backed purchase persistence,
      session-level joker inventory hydration,
      pure joker effect engine with controller orchestration,
      bottom-bar in-game action surface for owned jokers
    ]
key-files:
  created:
    [
      lib/src/core/gameplay/services/joker_engine.dart,
      lib/src/features/game/widgets/joker_bar.dart,
      test/core/joker_engine_test.dart,
      test/features/game/joker_bar_test.dart,
      .planning/phases/05-market-and-score-history/05-02-SUMMARY.md
    ]
  modified:
    [
      lib/src/core/repositories/wallet_repository.dart,
      lib/src/features/market/market_controller.dart,
      lib/src/features/game/game_controller.dart,
      lib/src/features/game/game_screen.dart,
      test/features/market/market_screen_test.dart,
      .planning/phases/05-market-and-score-history/05-02-PLAN.md,
      .planning/ROADMAP.md,
      .planning/STATE.md
    ]
key-decisions:
  - "Gold deduction and joker inventory increment now happen inside one repository-driven SQLite transaction path."
  - "Only owned jokers are shown in the in-game bottom bar; unavailable jokers are not faked as active gameplay actions."
  - "Joker board effects are centralized in `JokerEngine`, while the controller owns session updates, inventory consumption and persistence."
  - "Board-clearing jokers reuse the shared resolver/recovery pipeline so gravity, refill and solvability checks stay consistent."
patterns-established:
  - "MarketController -> WalletRepository transaction -> JokerInventoryRepository keeps economy writes atomic."
  - "GameController hydrates persisted inventory into session state and consumes joker stock after successful use."
  - "JokerBar is a thin owned-inventory UI surface; all gameplay rules remain in controller/engine services."
requirements-completed: [MKT-03, MKT-04, MKT-05]
completed: 2026-04-21
---

# Phase 05-02 Summary

**Purchased jokers now work end-to-end inside the live game**

## Accomplishments

- `WalletRepository` gained a transaction helper and `MarketController`
  now performs sufficient-gold check, balance deduction and inventory
  increment inside a single persisted flow.
- `GameController` now hydrates persisted joker inventory into the active
  game session, exposes owned joker counts to the UI and consumes stock
  after successful use.
- New `JokerEngine` implements all six documented gameplay effects:
  `Balık`, `Tekerlek`, `Lolipop Kırıcı`, `Serbest Değiştirme`,
  `Harf Karıştırma` and `Parti Güçlendiricisi`.
- Clear/remove style jokers route back through the shared
  clear/gravity/refill/recovery path instead of bypassing board logic.
- A new bottom `JokerBar` shows only currently owned jokers, supports
  active selection state for target-based jokers and gives short usage
  guidance inline on the game screen.
- Market widget fakes were updated to support the new transactional
  purchase path without coupling widget tests to a real database.

## Verification

- `flutter analyze` — No issues found
- `flutter test test/core/joker_engine_test.dart` — passed
- `flutter test test/features/game/joker_bar_test.dart` — passed
- `flutter test test/features/game/selection_finalize_test.dart` — passed
- `flutter test test/features/game/playable_word_count_and_recovery_test.dart`
  — passed
- `flutter test test/features/game/drag_selection_test.dart` — passed
- `flutter test test/features/market/market_screen_test.dart` — passed
- `python3 -c "from graphify.watch import _rebuild_code; from pathlib import Path; _rebuild_code(Path('.'))"`
  — graph rebuilt successfully
- MANUAL GATE passed: marketten satin alinan tum jokerler oyun ekraninin alt
  kisiminda goruldu, stoklari dogru yansidi ve altin dusumu dogru calisti
- MANUAL GATE passed: tum belgelenmis joker etkileri oyun tahtasinda goruldu,
  stok tuketimi uygulandi ve oyun akisi sonrasinda board oynanabilir kaldi

## Files Created/Modified

- `lib/src/core/repositories/wallet_repository.dart` — transaction wrapper for
  atomic market writes.
- `lib/src/features/market/market_controller.dart` — transactional purchase
  orchestration.
- `lib/src/core/gameplay/services/joker_engine.dart` — centralized joker
  effect logic.
- `lib/src/features/game/game_controller.dart` — inventory hydration,
  in-game joker activation and stock consumption.
- `lib/src/features/game/widgets/joker_bar.dart` — bottom-area owned-joker UI.
- `lib/src/features/game/game_screen.dart` — joker bar integrated into active
  game layout.
- `test/core/joker_engine_test.dart` — unit coverage for six joker effects.
- `test/features/game/joker_bar_test.dart` — widget coverage for owned-joker
  rendering and interaction state.
- `test/features/market/market_screen_test.dart` — fake transaction support
  for purchase-path coverage.

## Next Phase Readiness

- Phase 5 is now fully completed: market economy, in-game joker usage and
  score history UI all have implementation plus verification coverage.
- The next roadmap focus is Phase `06-01`, which can concentrate on device
  polish, manual mobile flow hardening and delivery-quality UX validation.
