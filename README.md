<div align="center">

# Crush Word

**Single-player Turkish word puzzle game built with Flutter**

Drag adjacent letters on a grid, form valid Turkish words, earn points.  
Fully offline — no server required.

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)](https://dart.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Download APK](https://img.shields.io/github/v/release/EnesDemir143/crush-word?label=Download%20APK&logo=android)](https://github.com/EnesDemir143/crush-word/releases/latest)

**[IEEE Technical Report](report/main.pdf)**

🌐 [English](README.md) · [Türkçe](README.tr.md)

</div>

---

## Screenshots

<p align="center">
  <img src="report/game-board.png" width="30%" alt="Game Board" />
  &nbsp;&nbsp;
  <img src="report/market.png" width="30%" alt="Market" />
  &nbsp;&nbsp;
  <img src="report/scor-hist.png" width="30%" alt="Score History" />
</p>
<p align="center">
  <em>Game screen &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; Market &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; Score History</em>
</p>

---

## How to Play

1. Choose grid size: **6×6** (Hard) · **8×8** (Medium) · **10×10** (Easy)
2. Choose move limit: **15 · 20 · 25**
3. Drag adjacent letters in 8 directions to form a word (minimum 3 letters)
4. Valid words are cleared, letters fall down, gaps fill with new letters
5. Score as high as possible before running out of moves

---

## Core Mechanics

### Weighted Letter Generation

The board is generated using a three-tier weighted algorithm based on Turkish letter frequencies:

| Tier | Weight | Letters |
|------|--------|---------|
| High frequency | 6 | A, E, İ, L, R, N |
| Medium frequency | 3 | K, M, T, S, Y, D |
| Low frequency | 1 | J, Ğ, F, V |

### Playable Board Guarantee

After every move, the board is analyzed with a **Trie + DFS + backtracking** algorithm. If no valid word exists, a two-stage recovery kicks in:

1. **Fisher-Yates shuffle** (max 5 attempts) — rearranges existing letters
2. **Full regeneration** (max 10 attempts) — generates a completely new board

The player is never shown a dead-end board.

### Scoring

Each letter carries a point value based on its frequency in Turkish:

| Points | Letters |
|--------|---------|
| 1 | A, E, İ, K, L, N, R, T |
| 2 | I, M, O, S, U |
| 3 | B, D, Ü, Y |
| 4 | C, Ç, Ş, Z |
| 5 | G, H, P |
| 7 | F, Ö, V |
| 8 | Ğ |
| 10 | J |

### Combo Scoring

Valid sub-words within the main word also score points.  
Example: **YAZAR** → YAZ + AZAR + YAZAR = 3 combos, all three words score.

### Power Tile System

Long words leave a power tile at the last letter's position. The power activates when that tile is used in another word:

| Word Length | Effect |
|-------------|--------|
| 4 letters | Clear row |
| 5 letters | Area blast |
| 6 letters | Clear column |
| 7+ letters | Mega blast |

---

## Market & Joker System

Jokers are purchased with in-game gold — no real money involved.

| Joker | Effect | Cost |
|-------|--------|------|
| Fish | Removes a random letter | 100 gold |
| Wheel | Clears the row and column of a selected letter | 200 gold |
| Lollipop Breaker | Removes a single letter | 75 gold |
| Free Swap | Swaps two adjacent letters | 125 gold |
| Letter Shuffle | Shuffles the entire board | 300 gold |
| Party Booster | Fully resets the board | 400 gold |

---

## Score History

Every game is saved automatically. The leaderboard shows:

- **Overall stats:** total games, highest score, average score, total words, longest word, total time
- **Game detail:** grid size, move count, words found, duration

---

## Architecture

Feature-first structure; game logic is fully decoupled from the UI and testable:

```
lib/src/
├── app/              # Bootstrap, routes, navigation
├── core/
│   ├── config/       # Game rules and runtime config
│   ├── models/       # Domain models
│   ├── repositories/ # Dictionary, profile, history, wallet, checkpoint
│   └── storage/      # SQLite & SharedPreferences services
└── features/
    ├── game/         # Game screen and controller
    ├── game_setup/   # Board and move selection
    ├── home/         # Home screen
    ├── market/       # Joker shop
    ├── onboarding/   # Username flow
    └── score_history/# Score history screen
```

Local data: `word_crush.db` (SQLite) — game results, joker inventory, wallet, session checkpoint.

---

## Tech Stack

- **Flutter / Dart** — cross-platform mobile development
- `sqflite` — local SQLite database
- `shared_preferences` — profile data
- `flutter_test` + `sqflite_common_ffi` — test infrastructure

---

## Download

Grab the latest APK from the [Releases](https://github.com/EnesDemir143/crush-word/releases/latest) page and install it on your Android device (enable "Install from unknown sources" if prompted).

## Run from Source

```bash
flutter pub get
flutter run
```

## Test

```bash
flutter analyze
flutter test
```

---

## Report

The IEEE-format technical report is in the `report/` folder:

- **[report/main.pdf](report/main.pdf)** — System architecture, algorithms, test results
- `report/main.tex` — LaTeX source

---

## Authors

**Enes Demir** & **Mert Şengül**

---

## License

[MIT License](LICENSE)
