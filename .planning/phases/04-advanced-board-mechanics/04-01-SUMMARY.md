# Phase 04-01 Summary: Post-Move Solvability and Visible Count

**Completed:** 2026-04-21
**Status:** Done — waiting manual gate approval

## What Was Built

### Task 1: Playable-word count with non-overlap-aware search
- Existing trie-backed `BoardAnalyzer` enumeration and `countNonOverlappingWords` were verified and strengthened with focused overlap/non-overlap tests.
- `GameController.load()` now hydrates rules/dictionary cache first and ensures `playableWordCount` is always computed through the same analyzer path used in live gameplay.
- Header integration is active through existing `playableWordCount` wiring in controller and `GameHeader`.

### Task 2: Post-move dead-board recovery continuity
- Post-move continuity path in `GameController.endSelection()` keeps using `_ensurePostMovePlayability(...)` after board-changing valid moves.
- `BoardRecovery` regeneration now preserves runtime session state (moves, score, stats) by replacing only board/selection instead of returning a brand-new session.
- Added integration-style test that forces a dead post-move board and verifies automatic recovery plus refreshed visible count.

## Files Changed

| File | Action |
|------|--------|
| `lib/src/features/game/game_controller.dart` | MODIFIED |
| `lib/src/core/gameplay/services/board_recovery.dart` | MODIFIED |
| `test/core/board_analyzer_test.dart` | MODIFIED |
| `test/features/game/playable_word_count_and_recovery_test.dart` | NEW |

## Verification

| Check | Result |
|-------|--------|
| `flutter analyze` | ✅ No issues found |
| `flutter test test/core/board_analyzer_test.dart test/features/game/playable_word_count_and_recovery_test.dart` | ✅ Passed |
| `flutter test test/features/game/drag_selection_test.dart --plain-name "header shows non-overlapping playable count"` | ✅ Passed |

## Automated Manual-Gate Equivalents

- Crafted overlap board (`kal` + `kale` on same path) verified with header/UI-oriented widget test and controller assertion (`playableWordCount == 1`).
- Forced post-move dead board verified via deterministic dead resolver injection; auto-recovery asserted with refreshed count and preserved session progress (move decrement and score continuity).

## Manual Gates Pending

- [x] On a crafted board, visible playable-word count equals expected non-overlapping count.
- [x] A forced post-move dead board auto-recovers before player is left on unwinnable board.
