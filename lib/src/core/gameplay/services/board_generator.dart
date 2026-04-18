import 'dart:math';

import 'package:crush_word/src/core/config/game_rules_config.dart';
import 'package:crush_word/src/core/gameplay/models/board_cell.dart';
import 'package:crush_word/src/core/gameplay/models/game_session.dart';
import 'package:crush_word/src/core/models/game_config.dart';

abstract class RandomSource {
  int nextInt(int max);
}

class DartRandomSource implements RandomSource {
  DartRandomSource([Random? random]) : _random = random ?? Random();

  final Random _random;

  @override
  int nextInt(int max) => _random.nextInt(max);
}

class BoardGenerator {
  BoardGenerator({RandomSource? randomSource})
    : _randomSource = randomSource ?? DartRandomSource();

  final RandomSource _randomSource;

  GameSession createSession({
    required GameConfig config,
    required GameRulesConfig rules,
  }) {
    final int gridSize = config.gridSize;

    return GameSession(
      config: config,
      board: List<BoardCell>.generate(
        gridSize * gridSize,
        (int index) => BoardCell(
          row: index ~/ gridSize,
          column: index % gridSize,
          letter: pickWeightedLetter(rules.boardGeneration),
        ),
        growable: false,
      ),
      movesLeft: config.moveLimit,
    );
  }

  /// Pick a single letter using the weighted frequency groups.
  ///
  /// Exposed publicly so that [BoardResolver] can reuse the same
  /// weighting logic for refill letters.
  String pickWeightedLetter(GameBoardGenerationRules rules) {
    final int threshold = _randomSource.nextInt(rules.totalWeight);
    int cursor = 0;

    for (final LetterFrequencyGroup group in rules.letterFrequencyGroups) {
      cursor += group.weight;

      if (threshold < cursor) {
        final int letterIndex =
            _randomSource.nextInt(group.letters.length);
        return group.letters[letterIndex];
      }
    }

    throw StateError(
      'Weighted letter selection failed even though '
      'total weight is positive.',
    );
  }
}
