import 'dart:math';

import 'package:crush_word/src/core/config/game_rules_config.dart';
import 'package:crush_word/src/core/gameplay/models/board_cell.dart';
import 'package:crush_word/src/core/gameplay/models/game_session.dart';
import 'package:crush_word/src/core/gameplay/services/board_analyzer.dart';
import 'package:crush_word/src/core/gameplay/services/board_generator.dart';

/// Recovers a dead board by first attempting to shuffle existing
/// letters, then falling back to full controlled regeneration.
///
/// This service is the initial-session guard: it guarantees that
/// the first board shown to the player always contains at least
/// one valid word. Post-move recovery and header counts are
/// deferred to Phase 4.
class BoardRecovery {
  BoardRecovery({
    required this.analyzer,
    required this.boardGenerator,
    this.maxShuffleAttempts = 5,
    this.maxRegenerateAttempts = 10,
    Random? random,
  }) : _random = random ?? Random();

  final BoardAnalyzer analyzer;
  final BoardGenerator boardGenerator;

  /// Maximum number of shuffle attempts before falling back to
  /// full regeneration.
  final int maxShuffleAttempts;

  /// Maximum number of full regeneration attempts.
  final int maxRegenerateAttempts;

  final Random _random;

  /// Strategy used during the most recent [ensurePlayable] call.
  ///
  /// Exposed for testing and diagnostics.
  RecoveryStrategy? lastStrategy;

  /// Ensures the given [session] has at least one playable word.
  ///
  /// If the board is already playable, returns it unchanged with
  /// [RecoveryStrategy.none]. Otherwise, tries shuffling the
  /// existing letters up to [maxShuffleAttempts] times, then
  /// falls back to full board regeneration.
  ///
  /// Throws [StateError] if neither strategy produces a playable
  /// board within the configured attempt limits.
  GameSession ensurePlayable({
    required GameSession session,
    required Set<String> dictionary,
    required GameRulesConfig rules,
  }) {
    // Check if the board is already playable.
    if (_isPlayable(session, dictionary)) {
      lastStrategy = RecoveryStrategy.none;
      return session;
    }

    // Strategy 1: Shuffle existing letters.
    for (int i = 0; i < maxShuffleAttempts; i++) {
      final GameSession shuffled = _shuffleBoard(session);

      if (_isPlayable(shuffled, dictionary)) {
        lastStrategy = RecoveryStrategy.shuffle;
        return shuffled;
      }
    }

    // Strategy 2: Full controlled regeneration.
    for (int i = 0; i < maxRegenerateAttempts; i++) {
      final GameSession regenerated = boardGenerator.createSession(
        config: session.config,
        rules: rules,
      );

      if (_isPlayable(regenerated, dictionary)) {
        lastStrategy = RecoveryStrategy.regenerate;
        return regenerated;
      }
    }

    throw StateError(
      'BoardRecovery failed to produce a playable board after '
      '$maxShuffleAttempts shuffle and $maxRegenerateAttempts '
      'regeneration attempts.',
    );
  }

  bool _isPlayable(GameSession session, Set<String> dictionary) {
    return analyzer.hasPlayableWord(
      board: session.board,
      gridSize: session.gridSize,
      words: dictionary,
    );
  }

  /// Produces a new session with the same letters shuffled into
  /// random positions while preserving all other session state.
  GameSession _shuffleBoard(GameSession session) {
    final List<String> letters = session.board
        .map((BoardCell cell) => cell.letter)
        .toList();

    // Fisher-Yates shuffle.
    for (int i = letters.length - 1; i > 0; i--) {
      final int j = _random.nextInt(i + 1);
      final String temp = letters[i];
      letters[i] = letters[j];
      letters[j] = temp;
    }

    final int gridSize = session.gridSize;
    final List<BoardCell> shuffledBoard = List<BoardCell>.generate(
      letters.length,
      (int index) => BoardCell(
        row: index ~/ gridSize,
        column: index % gridSize,
        letter: letters[index],
      ),
      growable: false,
    );

    return session.copyWith(board: shuffledBoard);
  }
}

/// Describes which recovery strategy was used.
enum RecoveryStrategy {
  /// The board was already playable.
  none,

  /// Existing letters were shuffled to form a valid word.
  shuffle,

  /// A completely new board was generated.
  regenerate,
}
