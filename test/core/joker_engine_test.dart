import 'dart:math';

import 'package:crush_word/src/core/config/game_rules_config.dart';
import 'package:crush_word/src/core/gameplay/models/board_cell.dart';
import 'package:crush_word/src/core/gameplay/models/game_session.dart';
import 'package:crush_word/src/core/gameplay/services/board_generator.dart';
import 'package:crush_word/src/core/gameplay/services/board_resolver.dart';
import 'package:crush_word/src/core/gameplay/services/joker_engine.dart';
import 'package:crush_word/src/core/models/game_config.dart';
import 'package:crush_word/src/core/models/game_difficulty.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('JokerEngine', () {
    late JokerEngine engine;
    late BoardResolver resolver;

    setUp(() {
      engine = JokerEngine(random: Random(7));
      resolver = BoardResolver(
        boardGenerator: BoardGenerator(randomSource: _FixedRandomSource(0)),
      );
    });

    test('fish removes three random cells through board resolution', () {
      final GameSession session = _buildSession();

      final JokerEffectResult result = engine.apply(
        jokerId: JokerIds.fish,
        session: session,
        rules: _rules,
        boardResolver: resolver,
      );

      expect(result.applied, isTrue);
      expect(result.removedCellIds, hasLength(3));
      expect(result.board, hasLength(session.board.length));
    });

    test('wheel clears the selected row and column', () {
      final GameSession session = _buildSession();

      final JokerEffectResult result = engine.apply(
        jokerId: JokerIds.wheel,
        session: session,
        rules: _rules,
        boardResolver: resolver,
        selectedCellIds: const <String>['1:1'],
      );

      expect(result.applied, isTrue);
      expect(
        result.removedCellIds.toSet(),
        equals(<String>{'0:1', '1:0', '1:1', '1:2', '2:1'}),
      );
    });

    test('lollipop breaker removes a single targeted cell', () {
      final GameSession session = _buildSession();

      final JokerEffectResult result = engine.apply(
        jokerId: JokerIds.lollipopBreaker,
        session: session,
        rules: _rules,
        boardResolver: resolver,
        selectedCellIds: const <String>['0:2'],
      );

      expect(result.applied, isTrue);
      expect(result.removedCellIds, equals(<String>['0:2']));
    });

    test('free swap exchanges two adjacent cells', () {
      final GameSession session = _buildSession();

      final JokerEffectResult result = engine.apply(
        jokerId: JokerIds.freeSwap,
        session: session,
        rules: _rules,
        boardResolver: resolver,
        selectedCellIds: const <String>['0:0', '0:1'],
      );

      expect(result.applied, isTrue);
      expect(result.board[0].letter, 'B');
      expect(result.board[1].letter, 'A');
      expect(result.removedCellIds, isEmpty);
    });

    test('shuffle letters keeps the same letters but reorders them', () {
      final GameSession session = _buildSession();

      final JokerEffectResult result = engine.apply(
        jokerId: JokerIds.shuffleLetters,
        session: session,
        rules: _rules,
        boardResolver: resolver,
      );

      expect(result.applied, isTrue);
      expect(
        result.board.map((BoardCell cell) => cell.letter).toSet(),
        equals(session.board.map((BoardCell cell) => cell.letter).toSet()),
      );
      expect(
        result.board.map((BoardCell cell) => cell.letter).toList(),
        isNot(
          equals(session.board.map((BoardCell cell) => cell.letter).toList()),
        ),
      );
    });

    test('party booster resets the entire board', () {
      final GameSession session = _buildSession();

      final JokerEffectResult result = engine.apply(
        jokerId: JokerIds.partyBooster,
        session: session,
        rules: _rules,
        boardResolver: resolver,
      );

      expect(result.applied, isTrue);
      expect(result.removedCellIds, hasLength(session.board.length));
      expect(result.board, hasLength(session.board.length));
    });
  });
}

GameSession _buildSession() {
  return GameSession(
    config: const GameConfig(
      difficulty: GameDifficulty.medium,
      difficultyLabel: 'Orta',
      gridSize: 3,
      moveLimit: 20,
    ),
    board: const <BoardCell>[
      BoardCell(row: 0, column: 0, letter: 'A'),
      BoardCell(row: 0, column: 1, letter: 'B'),
      BoardCell(row: 0, column: 2, letter: 'C'),
      BoardCell(row: 1, column: 0, letter: 'D'),
      BoardCell(row: 1, column: 1, letter: 'E'),
      BoardCell(row: 1, column: 2, letter: 'F'),
      BoardCell(row: 2, column: 0, letter: 'G'),
      BoardCell(row: 2, column: 1, letter: 'H'),
      BoardCell(row: 2, column: 2, letter: 'I'),
    ],
    movesLeft: 20,
  );
}

class _FixedRandomSource implements RandomSource {
  _FixedRandomSource(this.value);

  final int value;

  @override
  int nextInt(int max) => value % max;
}

final GameRulesConfig _rules = GameRulesConfig(
  setup: const GameSetupRules(
    difficultyOptions: <GameSetupOption>[
      GameSetupOption(
        difficulty: GameDifficulty.medium,
        label: 'Orta',
        gridLabel: '3x3 Grid',
        gridSize: 3,
      ),
    ],
    moveCountOptions: <GameMoveCountOption>[
      GameMoveCountOption(
        difficulty: GameDifficulty.medium,
        label: 'Orta',
        moveLimit: 20,
      ),
    ],
  ),
  boardGeneration: const GameBoardGenerationRules(
    letterFrequencyGroups: <LetterFrequencyGroup>[
      LetterFrequencyGroup(
        tier: LetterFrequencyTier.high,
        weight: 1,
        letters: <String>['X'],
      ),
    ],
  ),
);
