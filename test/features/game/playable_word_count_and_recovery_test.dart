import 'package:crush_word/src/core/config/game_rules_config.dart';
import 'package:crush_word/src/core/config/game_rules_loader.dart';
import 'package:crush_word/src/core/gameplay/models/board_cell.dart';
import 'package:crush_word/src/core/gameplay/models/game_session.dart';
import 'package:crush_word/src/core/gameplay/services/board_generator.dart';
import 'package:crush_word/src/core/gameplay/services/board_resolver.dart';
import 'package:crush_word/src/core/models/game_config.dart';
import 'package:crush_word/src/core/models/game_difficulty.dart';
import 'package:crush_word/src/core/repositories/dictionary_repository.dart';
import 'package:crush_word/src/features/game/game_controller.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'memory_session_checkpoint_repository.dart';

void main() {
  group('Playable count and post-move continuity', () {
    test('load computes non-overlapping playable word count', () async {
      final GameSession session = _buildSession(
        letters: const <String>[
          'k',
          'a',
          'l',
          'e',
          'x',
          'x',
          'x',
          'x',
          'x',
        ],
      );

      final GameController controller = GameController.fromSession(
        session,
        rulesLoader: _InMemoryRulesLoader(_rules),
        dictionaryRepository: DictionaryRepository(
          assetLoader: (_) async => 'kal\nkale\n',
        ),
        boardGenerator: BoardGenerator(
          randomSource: _FixedRandomSource(0),
        ),
        sessionCheckpointRepository: MemorySessionCheckpointRepository(),
      );

      await controller.load();

      // "kal" and "kale" overlap on the same cells; non-overlap
      // greedy count must keep only one.
      expect(controller.playableWordCount, 1);
      expect(controller.score, 0);
    });

    test('post-move dead board is recovered and count refreshed', () async {
      final GameSession session = _buildSession(
        letters: const <String>[
          'k',
          'a',
          'l',
          'x',
          'x',
          'x',
          'x',
          'x',
          'x',
        ],
        movesLeft: 5,
      );

      final DictionaryRepository dictionary = DictionaryRepository(
        assetLoader: (_) async => 'kal\n',
      );

      final GameController controller = GameController.fromSession(
        session,
        rulesLoader: _InMemoryRulesLoader(_rules),
        dictionaryRepository: dictionary,
        boardGenerator: BoardGenerator(
          randomSource: _LoopingRandomSource(<int>[0, 0, 1, 0, 2, 0]),
        ),
        boardResolver: _DeadBoardResolver(),
        sessionCheckpointRepository: MemorySessionCheckpointRepository(),
      );

      await controller.load();
      expect(controller.playableWordCount, greaterThan(0));

      // Play "kal" from top row; remaining board would be all 'x'
      // (dead) unless post-move recovery runs.
      final GameSession current = controller.session!;
      controller.startSelection(current.cellAt(row: 0, column: 0));
      controller.extendSelection(current.cellAt(row: 0, column: 1));
      controller.extendSelection(current.cellAt(row: 0, column: 2));

      await controller.endSelection();

      expect(controller.movesLeft, 4);
      expect(controller.score, 3);
      expect(controller.playableWordCount, greaterThan(0));
      expect(
        controller.session!.board.every((BoardCell cell) => cell.letter == 'x'),
        isFalse,
      );
      expect(
        controller.session!.board.any((BoardCell cell) => cell.letter == 'k'),
        isTrue,
      );
      expect(
        controller.session!.board.any((BoardCell cell) => cell.letter == 'a'),
        isTrue,
      );
      expect(
        controller.session!.board.any((BoardCell cell) => cell.letter == 'l'),
        isTrue,
      );
    });
  });
}

GameSession _buildSession({
  required List<String> letters,
  int movesLeft = 10,
}) {
  const int gridSize = 3;
  return GameSession(
    config: const GameConfig(
      difficulty: GameDifficulty.medium,
      difficultyLabel: 'Orta',
      gridSize: gridSize,
      moveLimit: 20,
    ),
    board: List<BoardCell>.generate(
      letters.length,
      (int index) => BoardCell(
        row: index ~/ gridSize,
        column: index % gridSize,
        letter: letters[index],
      ),
      growable: false,
    ),
    movesLeft: movesLeft,
  );
}

class _InMemoryRulesLoader extends GameRulesLoader {
  _InMemoryRulesLoader(this._rules)
    : super(bundle: _ThrowingBundle(), assetPath: 'unused');

  final GameRulesConfig _rules;

  @override
  Future<GameRulesConfig> load() async => _rules;
}

class _ThrowingBundle extends CachingAssetBundle {
  @override
  Future<String> loadString(String key, {bool cache = true}) {
    throw UnimplementedError();
  }

  @override
  Future<ByteData> load(String key) {
    throw UnimplementedError();
  }
}

class _FixedRandomSource implements RandomSource {
  _FixedRandomSource(this.value);

  final int value;

  @override
  int nextInt(int max) => value % max;
}

class _LoopingRandomSource implements RandomSource {
  _LoopingRandomSource(this.values);

  final List<int> values;
  int _index = 0;

  @override
  int nextInt(int max) {
    final int value = values[_index % values.length];
    _index += 1;
    return value % max;
  }
}

class _DeadBoardResolver extends BoardResolver {
  _DeadBoardResolver() : super(boardGenerator: BoardGenerator());

  @override
  BoardResolveResult resolve({
    required List<BoardCell> board,
    required List<String> selectedCellIds,
    required int gridSize,
    required GameBoardGenerationRules rules,
    int? wordLength,
  }) {
    final List<BoardCell> deadBoard = List<BoardCell>.generate(
      gridSize * gridSize,
      (int index) => BoardCell(
        row: index ~/ gridSize,
        column: index % gridSize,
        letter: 'x',
      ),
      growable: false,
    );

    final List<BoardCell> removedCells = board
        .where((BoardCell cell) => selectedCellIds.contains(cell.id))
        .toList(growable: false);

    return BoardResolveResult(board: deadBoard, removedCells: removedCells);
  }
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
        letters: <String>['k'],
      ),
      LetterFrequencyGroup(
        tier: LetterFrequencyTier.medium,
        weight: 1,
        letters: <String>['a'],
      ),
      LetterFrequencyGroup(
        tier: LetterFrequencyTier.low,
        weight: 1,
        letters: <String>['l'],
      ),
    ],
  ),
  scoring: ScoringConfig(letterScores: const <String, int>{'K': 1, 'A': 1, 'L': 1}),
);
