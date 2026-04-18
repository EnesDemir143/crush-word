import 'package:flutter_test/flutter_test.dart';

import 'package:crush_word/src/core/config/game_rules_config.dart';
import 'package:crush_word/src/core/gameplay/models/game_session.dart';
import 'package:crush_word/src/core/gameplay/services/board_generator.dart';
import 'package:crush_word/src/core/models/game_config.dart';
import 'package:crush_word/src/core/models/game_difficulty.dart';

void main() {
  group('BoardGenerator', () {
    test('creates square sessions for all supported setup sizes', () {
      final BoardGenerator generator = BoardGenerator(
        randomSource: _LoopingRandomSource(<int>[0, 0]),
      );

      final List<GameConfig> configs = <GameConfig>[
        const GameConfig(
          difficulty: GameDifficulty.hard,
          difficultyLabel: 'Zor',
          gridSize: 6,
          moveLimit: 15,
        ),
        const GameConfig(
          difficulty: GameDifficulty.medium,
          difficultyLabel: 'Orta',
          gridSize: 8,
          moveLimit: 20,
        ),
        const GameConfig(
          difficulty: GameDifficulty.easy,
          difficultyLabel: 'Kolay',
          gridSize: 10,
          moveLimit: 25,
        ),
      ];

      for (final GameConfig config in configs) {
        final GameSession session = generator.createSession(
          config: config,
          rules: _testRulesConfig,
        );

        expect(session.board, hasLength(config.gridSize * config.gridSize));
        expect(session.rows, hasLength(config.gridSize));
        expect(session.movesLeft, config.moveLimit);
        expect(session.cellAt(row: 0, column: 0).letter, 'A');
        expect(
          session
              .cellAt(row: config.gridSize - 1, column: config.gridSize - 1)
              .letter,
          'A',
        );
      }
    });

    test('uses weighted group thresholds instead of flat uniform picks', () {
      final BoardGenerator generator = BoardGenerator(
        randomSource: _LoopingRandomSource(<int>[0, 0, 6, 0, 9, 0, 5, 1]),
      );

      final GameSession session = generator.createSession(
        config: const GameConfig(
          difficulty: GameDifficulty.hard,
          difficultyLabel: 'Zor',
          gridSize: 2,
          moveLimit: 15,
        ),
        rules: _testRulesConfig,
      );

      expect(session.board.map((cell) => cell.letter).toList(), <String>[
        'A',
        'K',
        'J',
        'E',
      ]);
    });
  });
}

const GameRulesConfig _testRulesConfig = GameRulesConfig(
  setup: GameSetupRules(
    difficultyOptions: <GameSetupOption>[
      GameSetupOption(
        difficulty: GameDifficulty.hard,
        label: 'Zor',
        gridLabel: '6x6 Grid',
        gridSize: 6,
      ),
    ],
    moveCountOptions: <GameMoveCountOption>[
      GameMoveCountOption(
        difficulty: GameDifficulty.hard,
        label: 'Zor',
        moveLimit: 15,
      ),
    ],
  ),
  boardGeneration: GameBoardGenerationRules(
    letterFrequencyGroups: <LetterFrequencyGroup>[
      LetterFrequencyGroup(
        tier: LetterFrequencyTier.high,
        weight: 6,
        letters: <String>['A', 'E'],
      ),
      LetterFrequencyGroup(
        tier: LetterFrequencyTier.medium,
        weight: 3,
        letters: <String>['K'],
      ),
      LetterFrequencyGroup(
        tier: LetterFrequencyTier.low,
        weight: 1,
        letters: <String>['J'],
      ),
    ],
  ),
);

class _LoopingRandomSource implements RandomSource {
  _LoopingRandomSource(this.values);

  final List<int> values;
  int _index = 0;

  @override
  int nextInt(int max) {
    final int value = values[_index % values.length];
    _index += 1;

    if (value >= max) {
      throw RangeError(
        'Test random value $value must be smaller than requested max $max.',
      );
    }

    return value;
  }
}
