# Word Crush — Architecture Report

> Generated: 2026-04-24

---

## Executive Summary

**Word Crush** is a Turkish-language word puzzle game built with Flutter. The architecture follows a strict 3-layer structure (presentation → domain → data) with no cloud services — everything runs locally on-device.

---

## 1. Architecture Layers

```
┌─────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                       │
│  Screens · Widgets · Navigation · ChangeNotifier controllers│
│  GameScreen, MarketScreen, HomeScreen, ScoreHistoryScreen   │
└────────────────────────┬────────────────────────────────────┘
                         │ uses
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                    DOMAIN LAYER                             │
│         Pure Dart — no Flutter / no I/O dependencies        │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐  │
│  │ Board        │  │ Scoring      │  │ Jokers & Powers  │  │
│  │ Generator    │  │ Engine       │  │ JokerEngine      │  │
│  │ Resolver     │  │ ComboDetector│  │ PowerEngine      │  │
│  │ Analyzer     │  │ ComboScoring │  │                  │  │
│  │ Recovery     │  │ Engine       │  │                  │  │
│  └──────────────┘  └──────────────┘  └──────────────────┘  │
│  Models: GameSession · BoardCell · GameResult · GameConfig  │
└────────────────────────┬────────────────────────────────────┘
                         │ uses
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                      DATA LAYER                             │
│  ┌────────────────────────┐  ┌─────────────────────────┐   │
│  │      Repositories      │  │     AppDatabase         │   │
│  │ DictionaryRepository   │  │  SQLite (sqflite v2)    │   │
│  │ ProfileRepository      │  │  Tables:                │   │
│  │ GameHistoryRepository  │  │   game_results          │   │
│  │ SessionCheckpointRepo  │  │   session_checkpoint    │   │
│  │ JokerInventoryRepo     │  │   wallet_balance        │   │
│  │ WalletRepository       │  │   joker_inventory       │   │
│  └────────────────────────┘  └─────────────────────────┘   │
│  Assets: tr_words.txt · game_rules.json · joker images      │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. Component List (Architecture Diagram Nodes)

### 2.1 Entry Point & Shell

| Component | File | Role |
|---|---|---|
| `main.dart` | `lib/main.dart` | App initialization |
| `WordCrushApp` | `lib/src/app/word_crush_app.dart` | Root MaterialApp, theme |
| `AppRouter` | `lib/src/app/app_router.dart` | Route generation with DI |
| `AppRoutes` | `lib/src/app/app_routes.dart` | Route name constants |

### 2.2 Screens (Presentation)

| Screen | Route | Purpose |
|---|---|---|
| `UsernameGate` | `/onboarding` | First-run name entry; subsequent-run auto-skip |
| `HomeScreen` | `/home` | Main menu (New Game / Skor Tablosu / Market) |
| `NewGameScreen` | `/new_game` | Two-step difficulty & move-count wizard |
| `GameScreen` | `/game` | Active gameplay surface |
| `MarketScreen` | `/market` | Joker purchase shop |
| `ScoreHistoryScreen` | `/score_history` | Past game list with aggregate stats |

### 2.3 Controllers (State Management — ChangeNotifier)

| Controller | Manages | Key Methods |
|---|---|---|
| `GameController` | Entire game session | `load`, `startSelection`, `extendSelection`, `endSelection`, `activateJoker`, `confirmExit` |
| `GameSetupController` | Difficulty wizard state | Step navigation |
| `MarketController` | Gold balance, joker inventory, purchase flow | `load`, `purchaseJoker`, `canPurchase` |
| `HistoryController` | Past game list + aggregate summary | `load`, `_deriveSummary` |

### 2.4 Domain Services (Pure Logic)

| Service | Responsibility |
|---|---|
| `BoardGenerator` | Creates initial `GameSession` with weighted random letters |
| `BoardResolver` | Pipeline: power activation → clear → gravity → refill → power creation |
| `BoardAnalyzer` | Trie + DFS: finds valid words, counts non-overlapping words |
| `BoardRecovery` | Shuffle / regenerate when grid has no playable words |
| `WordValidator` | Minimum length check + Turkish normalization + dictionary lookup |
| `ScoringEngine` | Maps letters to points via config table |
| `ComboDetector` | Finds contiguous sub-words (3+ chars) within played word |
| `ComboScoringEngine` | Adds sub-word scores to main word total |
| `PowerEngine` | Determines power type for word length; activates row/col/area/mega effects |
| `JokerEngine` | Applies joker effects (fish, wheel, lollipop, swap, shuffle, party) |

### 2.5 Repositories (Data Access)

| Repository | Storage | Contents |
|---|---|---|
| `DictionaryRepository` | Memory (`Set<String>`) + asset file | ~100 K Turkish words |
| `ProfileRepository` | SharedPreferences | Player username |
| `GameHistoryRepository` | SQLite `game_results` | Completed game records (newest-first) |
| `SessionCheckpointRepository` | SQLite `session_checkpoint` | Full JSON snapshot of active session |
| `WalletRepository` | SQLite `wallet_balance` | Gold balance |
| `JokerInventoryRepository` | SQLite `joker_inventory` | Per-joker quantity |

### 2.6 Persistence

| Component | Technology | Details |
|---|---|---|
| `AppDatabase` | `sqflite` | Schema v2; migrations; FK constraints on |
| `LocalStorageService` | `shared_preferences` | Interface + SharedPreferences impl |

### 2.7 Configuration

| Component | File | Contents |
|---|---|---|
| `GameRulesLoader` | `core/config/game_rules_loader.dart` | Loads `game_rules.json` from asset bundle |
| `GameRulesConfig` | model | Root config object |
| `ScoringConfig` | model | Letter → points map |
| `MarketRules` | model | Joker definitions + initial gold |
| `GameBoardGenerationRules` | model | Letter frequency groups (high/medium/low) |
| `PowerTileConfig` | model | Word-length → power-type thresholds |

### 2.8 Domain Models

```
GameConfig         difficulty · gridSize · moveLimit · labels
GameSession        config · board[N×N] · movesLeft · score · wordsFoundCount
                   longestWord · playableWordCount · startedAt · selectedCellIds
                   jokerInventory
BoardCell          row · col · letter · tileId · power(PowerTile?) · isJoker
PowerTile          type: rowClear | columnClear | areaBlast | megaBlast
GameResult         id · config · score · wordsFoundCount · longestWord · duration
                   completedAt
AppUser            username
JokerInventory     jokerId · quantity
MarketJokerDefinition  id · name · cost · description · purpose · usage
```

---

## 3. Key Data Flows

### 3.1 Word Submission

```
User traces letters
  → GameController.endSelection()
    → WordValidator.validate()          [3-letter min + dictionary check]
      IF invalid → decrement moves, InvalidAttemptFeedback, return
      IF valid →
        ScoringEngine.score()
        ComboDetector.detect()          [sub-word scan]
        ComboScoringEngine.scoreWithCombo()
        BoardResolver.resolve()
          └─ PowerEngine.activate()     [additional cells if power tile hit]
          └─ clear → gravity → refill
          └─ PowerEngine.powerForWord() [attach new power if word long enough]
        BoardRecovery.ensurePlayable()  [shuffle/regenerate if dead]
        BoardAnalyzer.countNonOverlappingWords()
        Update GameSession
        SessionCheckpointRepository.save()
        IF movesLeft == 0:
          GameHistoryRepository.saveResult()
          SessionCheckpointRepository.clear()
  → notifyListeners() → UI rebuild
```

### 3.2 Joker Purchase

```
MarketScreen tap "Satın Al"
  → MarketController.purchaseJoker(joker)
    → WalletRepository.runInTransaction()
        read gold
        IF gold >= cost:
          WalletRepository.setGoldBalance(gold - cost)
          JokerInventoryRepository.setQuantity(jokerId, qty + 1)
          return success
        ELSE return insufficientGold
  → notifyListeners() → UI shows new gold + stock
```

### 3.3 Session Resume

```
App relaunch → GameScreen
  → GameController.load()
    → SessionCheckpointRepository.load()
      IF exists → hydrate GameSession from JSON
      ELSE → BoardGenerator.createSession() + BoardRecovery.ensurePlayable()
```

---

## 4. Technologies & Dependencies

| Category | Package | Version | Purpose |
|---|---|---|---|
| Framework | `flutter` | SDK | UI & platform layer |
| Database | `sqflite` | ^2.4.2 | SQLite persistence |
| Key-value store | `shared_preferences` | ^2.5.3 | Username storage |
| Path utilities | `path` | ^1.9.1 | Database file path |
| Icons | `cupertino_icons` | ^1.0.8 | iOS icon set |
| Test DB | `sqflite_common_ffi` | ^2.3.6 | Desktop/unit test SQLite |
| Linting | `flutter_lints` | ^6.0.0 | Dart analysis rules |

**Cloud services: None** — fully offline.

---

## 5. Asset Files

| Path | Role |
|---|---|
| `assets/dictionary/tr_words.txt` | Turkish word list (~100 K words), one per line |
| `assets/dictionary/hunspell-tr-main/` | Source Hunspell dictionary (reference only) |
| `assets/config/game_rules.json` | Master game config (scoring, market, board gen, power tiles) |
| `assets/images/word_crush_hero.png` | Home/onboarding hero image |
| `assets/images/gameplay_background.png` | Game screen background |
| `assets/images/jokers/fish.png` | Fish joker icon |
| `assets/images/jokers/wheel.png` | Wheel joker icon |
| `assets/images/jokers/lollipop_breaker.png` | Lollipop Breaker icon |
| `assets/images/jokers/free_swap.png` | Free Swap icon |
| `assets/images/jokers/shuffle_letters.png` | Shuffle Letters icon |
| `assets/images/jokers/party_booster.png` | Party Booster icon |

---

## 6. SQLite Schema (v2)

```sql
CREATE TABLE game_results (
  id                TEXT PRIMARY KEY,
  completed_at      TEXT,
  difficulty        TEXT,       -- easy | medium | hard
  grid_size         INTEGER,
  starting_moves    INTEGER,
  score             INTEGER,
  words_found_count INTEGER,
  longest_word      TEXT,
  duration_seconds  INTEGER
);

CREATE TABLE session_checkpoint (
  checkpoint_id     TEXT PRIMARY KEY,  -- always "active_session"
  game_config_json  TEXT,
  board_json        TEXT,              -- JSON array of BoardCell
  remaining_moves   INTEGER,
  elapsed_seconds   INTEGER,
  current_score     INTEGER,
  words_found_count INTEGER,
  longest_word      TEXT,
  selected_path_json TEXT,
  power_tiles_json  TEXT,
  updated_at        TEXT
);

CREATE TABLE wallet_balance (
  wallet_id     TEXT PRIMARY KEY,      -- always "player_wallet"
  gold_balance  INTEGER
);

CREATE TABLE joker_inventory (
  joker_id  TEXT PRIMARY KEY,
  quantity  INTEGER
);
```

---

## 7. Test Coverage

| Area | Test Files | Type |
|---|---|---|
| Board generator | `board_generator_test.dart` | Unit |
| Board resolver | `board_resolver_test.dart` | Unit |
| Board analyzer | `board_analyzer_test.dart` | Unit |
| Scoring | `scoring_engine_test.dart` | Unit |
| Combo engine | `combo_engine_test.dart` | Unit |
| Power engine | `power_engine_test.dart` | Unit |
| Joker engine | `joker_engine_test.dart` | Unit |
| Word validator | `word_validator_test.dart` | Unit |
| Dictionary | `dictionary_repository_test.dart` | Unit |
| App bootstrap | `app_bootstrap_test.dart` | Integration |
| Onboarding | `username_gate_test.dart` | Widget |
| Game setup | `new_game_screen_test.dart` | Widget |
| Word selection | `selection_finalize_test.dart` | Integration |
| Drag selection | `drag_selection_test.dart` | Integration |
| Game over flow | `endgame_flow_test.dart` | Integration |
| Board recovery | `playable_word_count_and_recovery_test.dart` | Integration |
| Game header | `game_header_test.dart` | Widget |
| Joker bar | `joker_bar_test.dart` | Widget |
| Letter grid | `letter_grid_effect_test.dart` | Widget |
| Market | `market_screen_test.dart` | Widget |
| Score history | `score_history_screen_test.dart` | Widget |

**Total: 22 test files · 128 test cases (all passing)**

---

## 8. Routing Map

```
Startup
  └─ UsernameGate (/onboarding)
       └─ IF no saved username: show dialog
       └─ IF username exists: auto-redirect
            └─ HomeScreen (/home)
                 ├─ NewGameScreen (/new_game)
                 │    └─ GameScreen (/game) ← config passed as route arg
                 ├─ ScoreHistoryScreen (/score_history)
                 └─ MarketScreen (/market)
```

---

## 9. Design Patterns

| Pattern | Usage |
|---|---|
| **Immutable value objects** | `GameSession`, `BoardCell`, all domain models — updated via `copyWith()` |
| **Dependency injection** | Services & repositories injected into controllers; enables mocking |
| **Repository pattern** | All I/O abstracted; swap SQLite for memory in tests |
| **ChangeNotifier** | Controllers notify UI on state changes |
| **Pure functions** | Board services (resolver, analyzer) — deterministic, side-effect-free |
| **Lazy initialization** | `GameController` initializes services on first use |
| **Trie + DFS** | `BoardAnalyzer` — prefix pruning for efficient word search |
| **Weighted random** | `BoardGenerator` — letter frequency tiers for playable boards |
| **Pipeline** | `BoardResolver` — sequential transformations (clear → gravity → refill → power) |
