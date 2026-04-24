import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:crush_word/src/core/config/game_rules_config.dart';
import 'package:crush_word/src/core/gameplay/models/board_cell.dart';
import 'package:crush_word/src/core/gameplay/models/game_session.dart';
import 'package:crush_word/src/core/gameplay/services/board_analyzer.dart';
import 'package:crush_word/src/core/gameplay/services/board_generator.dart';
import 'package:crush_word/src/core/gameplay/services/board_recovery.dart';
import 'package:crush_word/src/core/models/game_config.dart';
import 'package:crush_word/src/core/models/game_difficulty.dart';

// ──────────────────────────────────────────────
// Test helpers
// ──────────────────────────────────────────────

/// Creates a 2×2 board from the 4 given letters laid out as:
///   [0] [1]
///   [2] [3]
List<BoardCell> _board2x2(List<String> letters) {
  assert(letters.length == 4);

  return List<BoardCell>.generate(
    4,
    (int i) => BoardCell(row: i ~/ 2, column: i % 2, letter: letters[i]),
    growable: false,
  );
}

/// Creates an NxN board from a flat list of letters.
List<BoardCell> _boardNxN(int size, List<String> letters) {
  assert(letters.length == size * size);

  return List<BoardCell>.generate(
    letters.length,
    (int i) => BoardCell(row: i ~/ size, column: i % size, letter: letters[i]),
    growable: false,
  );
}

/// A tiny dictionary for controlled test scenarios.
const Set<String> _miniDictionary = <String>{
  'kal', // 3-letter word
  'kalem', // 5-letter word
  'ata', // 3-letter word with repeat-letter pattern
  'ela', // 3-letter word
};

/// A dictionary that contains no word formable on the dead board.
const Set<String> _impossibleDictionary = <String>{'xyz', 'qwerty'};

const GameConfig _testConfig = GameConfig(
  difficulty: GameDifficulty.hard,
  difficultyLabel: 'Zor',
  gridSize: 2,
  moveLimit: 15,
);

const GameRulesConfig _testRules = GameRulesConfig(
  setup: GameSetupRules(
    difficultyOptions: <GameSetupOption>[
      GameSetupOption(
        difficulty: GameDifficulty.hard,
        label: 'Zor',
        gridLabel: '2x2',
        gridSize: 2,
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
        letters: <String>['k', 'a', 'l'],
      ),
      LetterFrequencyGroup(
        tier: LetterFrequencyTier.medium,
        weight: 3,
        letters: <String>['e'],
      ),
      LetterFrequencyGroup(
        tier: LetterFrequencyTier.low,
        weight: 1,
        letters: <String>['m'],
      ),
    ],
  ),
);

// ──────────────────────────────────────────────
// BoardAnalyzer tests
// ──────────────────────────────────────────────

void main() {
  group('BoardAnalyzer', () {
    late BoardAnalyzer analyzer;

    setUp(() {
      analyzer = BoardAnalyzer();
    });

    test('finds a playable word on a valid board', () {
      // Board:  k a
      //         l _
      // Path k→a→l = "kal" which is in dictionary.
      final List<BoardCell> board = _board2x2(<String>['k', 'a', 'l', 'x']);

      final bool result = analyzer.hasPlayableWord(
        board: board,
        gridSize: 2,
        words: _miniDictionary,
      );

      expect(result, isTrue);
    });

    test('reports false on a crafted dead board', () {
      // Board: x x
      //        x x
      // No word in dictionary can be formed.
      final List<BoardCell> board = _board2x2(<String>['x', 'x', 'x', 'x']);

      final bool result = analyzer.hasPlayableWord(
        board: board,
        gridSize: 2,
        words: _miniDictionary,
      );

      expect(result, isFalse);
    });

    test('prunes prefixes not present in the trie', () {
      // Board: z z
      //        z z
      // No prefix "z..." exists in dictionary, so all branches
      // should be pruned at depth 1 without reaching depth 2+.
      final List<BoardCell> board = _board2x2(<String>['z', 'z', 'z', 'z']);

      final bool result = analyzer.hasPlayableWord(
        board: board,
        gridSize: 2,
        words: _miniDictionary,
      );

      expect(result, isFalse);
    });

    test('does not reuse the same cell in a single path', () {
      // Board: a t
      //        x x
      // "ata" requires a→t→a, but there is only one 'a' cell.
      // If no-reuse is enforced, this must return false.
      final List<BoardCell> board = _board2x2(<String>['a', 't', 'x', 'x']);

      final bool result = analyzer.hasPlayableWord(
        board: board,
        gridSize: 2,
        words: const <String>{'ata'},
      );

      expect(result, isFalse);
    });

    test('finds word using diagonal adjacency', () {
      // Board: e x
      //        x l  then we need 'a' — wait let me adjust.
      // Board: e l
      //        x a
      // Path e(0,0)→l(0,1)→a(1,1) = "ela" is in dictionary.
      // l and a are vertically adjacent, e and l horizontally.
      final List<BoardCell> board = _board2x2(<String>['e', 'l', 'x', 'a']);

      final bool result = analyzer.hasPlayableWord(
        board: board,
        gridSize: 2,
        words: _miniDictionary,
      );

      expect(result, isTrue);
    });

    test('returns false on empty board', () {
      final bool result = analyzer.hasPlayableWord(
        board: const <BoardCell>[],
        gridSize: 0,
        words: _miniDictionary,
      );

      expect(result, isFalse);
    });

    test('returns false with empty dictionary', () {
      final List<BoardCell> board = _board2x2(<String>['k', 'a', 'l', 'e']);

      final bool result = analyzer.hasPlayableWord(
        board: board,
        gridSize: 2,
        words: const <String>{},
      );

      expect(result, isFalse);
    });

    test('handles larger board with valid word', () {
      // 3×3 board with "kal" formable via adjacent path.
      //   k a x
      //   x l x
      //   x x x
      final List<BoardCell> board = _boardNxN(3, <String>[
        'k',
        'a',
        'x',
        'x',
        'l',
        'x',
        'x',
        'x',
        'x',
      ]);

      final bool result = analyzer.hasPlayableWord(
        board: board,
        gridSize: 3,
        words: _miniDictionary,
      );

      expect(result, isTrue);
    });

    test('rejects words shorter than minimum length', () {
      // Dictionary with only 2-letter words.
      final bool result = analyzer.hasPlayableWord(
        board: _board2x2(<String>['a', 'b', 'c', 'd']),
        gridSize: 2,
        words: const <String>{'ab', 'bc'},
      );

      expect(result, isFalse);
    });

    test('counts non-overlapping words on the same board', () {
      final List<BoardCell> board = _boardNxN(3, <String>[
        'k',
        'a',
        'l',
        'x',
        'x',
        'x',
        'e',
        'l',
        'a',
      ]);

      final int count = analyzer.countNonOverlappingWords(
        board: board,
        gridSize: 3,
        words: const <String>{'kal', 'ela'},
      );

      expect(count, 2);
    });

    test('counts overlapping candidates as a single playable slot', () {
      final List<BoardCell> board = _board2x2(<String>['k', 'a', 'l', 'e']);

      final int count = analyzer.countNonOverlappingWords(
        board: board,
        gridSize: 2,
        words: const <String>{'kal', 'kale'},
      );

      expect(count, 1);
    });
  });

  // ──────────────────────────────────────────────
  // BoardRecovery tests
  // ──────────────────────────────────────────────

  group('BoardRecovery', () {
    late BoardAnalyzer analyzer;
    late BoardGenerator generator;

    setUp(() {
      analyzer = BoardAnalyzer();
      generator = BoardGenerator();
    });

    test('returns original session when board is already playable', () {
      final GameSession playableSession = GameSession(
        config: _testConfig,
        board: _board2x2(<String>['k', 'a', 'l', 'x']),
        movesLeft: 15,
      );

      final BoardRecovery recovery = BoardRecovery(
        analyzer: analyzer,
        boardGenerator: generator,
      );

      final GameSession result = recovery.ensurePlayable(
        session: playableSession,
        dictionary: _miniDictionary,
        rules: _testRules,
      );

      expect(result, equals(playableSession));
      expect(recovery.lastStrategy, RecoveryStrategy.none);
    });

    test('recovers a dead board via shuffle or regeneration', () {
      // 3×3 board with k, a, l placed non-adjacently so no
      // word can be formed in the initial arrangement.
      final GameConfig config3x3 = _testConfig.copyWith(gridSize: 3);

      final GameSession deadSession = GameSession(
        config: config3x3,
        board: _boardNxN(3, <String>[
          'k',
          'x',
          'l',
          'x',
          'x',
          'x',
          'a',
          'x',
          'x',
        ]),
        movesLeft: 15,
      );

      // Verify this arrangement is indeed dead.
      expect(
        analyzer.hasPlayableWord(
          board: deadSession.board,
          gridSize: 3,
          words: _miniDictionary,
        ),
        isFalse,
      );

      // Use a seeded random for deterministic shuffle.
      final BoardRecovery recovery = BoardRecovery(
        analyzer: analyzer,
        boardGenerator: BoardGenerator(randomSource: _FixedRandomSource(0)),
        random: Random(42),
        maxShuffleAttempts: 20,
        maxRegenerateAttempts: 20,
      );

      final GameSession result = recovery.ensurePlayable(
        session: deadSession,
        dictionary: _miniDictionary,
        rules: GameRulesConfig(
          setup: _testRules.setup,
          boardGeneration: _testRules.boardGeneration,
        ),
      );

      // Recovery must produce a playable board.
      expect(
        analyzer.hasPlayableWord(
          board: result.board,
          gridSize: 3,
          words: _miniDictionary,
        ),
        isTrue,
      );

      // Strategy should not be none.
      expect(recovery.lastStrategy, isNot(RecoveryStrategy.none));
    });

    test('prefers shuffle over regeneration', () {
      // All letters are 'x': shuffle is futile but must be
      // attempted before regeneration. With
      // maxRegenerateAttempts=0 the service should throw
      // after exhausting shuffle attempts only.
      final BoardRecovery recovery = BoardRecovery(
        analyzer: analyzer,
        boardGenerator: generator,
        maxShuffleAttempts: 3,
        maxRegenerateAttempts: 0,
      );

      final GameSession deadSession = GameSession(
        config: _testConfig,
        board: _board2x2(<String>['x', 'x', 'x', 'x']),
        movesLeft: 15,
      );

      expect(
        () => recovery.ensurePlayable(
          session: deadSession,
          dictionary: _miniDictionary,
          rules: _testRules,
        ),
        throwsStateError,
      );
    });

    test('falls back to regeneration when shuffle cannot help', () {
      // All cells are 'x' — shuffle is futile.
      // The generator cycles k→a→l→k producing a board
      // where "kal" is formable.
      final GameSession deadSession = GameSession(
        config: _testConfig,
        board: _board2x2(<String>['x', 'x', 'x', 'x']),
        movesLeft: 15,
      );

      final BoardGenerator playableGenerator = BoardGenerator(
        randomSource: _LoopingRandomSource(
          // Cycle: threshold=0→high, letterIdx=0→'k',
          //        threshold=0→high, letterIdx=1→'a',
          //        threshold=0→high, letterIdx=2→'l',
          //        threshold=0→high, letterIdx=0→'k'
          <int>[0, 0, 0, 1, 0, 2, 0, 0],
        ),
      );

      final BoardRecovery recovery = BoardRecovery(
        analyzer: analyzer,
        boardGenerator: playableGenerator,
        maxShuffleAttempts: 1,
        maxRegenerateAttempts: 5,
      );

      final GameSession result = recovery.ensurePlayable(
        session: deadSession,
        dictionary: _miniDictionary,
        rules: _testRules,
      );

      expect(
        analyzer.hasPlayableWord(
          board: result.board,
          gridSize: 2,
          words: _miniDictionary,
        ),
        isTrue,
      );
      expect(recovery.lastStrategy, RecoveryStrategy.regenerate);
    });

    test('throws when all recovery attempts are exhausted', () {
      final GameSession deadSession = GameSession(
        config: _testConfig,
        board: _board2x2(<String>['x', 'x', 'x', 'x']),
        movesLeft: 15,
      );

      // Use a generator that always produces unplayable boards.
      final BoardGenerator deadGenerator = BoardGenerator(
        randomSource: _LoopingRandomSource(<int>[9, 0]),
      );

      final BoardRecovery recovery = BoardRecovery(
        analyzer: analyzer,
        boardGenerator: deadGenerator,
        maxShuffleAttempts: 1,
        maxRegenerateAttempts: 1,
      );

      expect(
        () => recovery.ensurePlayable(
          session: deadSession,
          dictionary: _impossibleDictionary,
          rules: _testRules,
        ),
        throwsStateError,
      );
    });
  });
}

// ──────────────────────────────────────────────
// Test doubles
// ──────────────────────────────────────────────

class _LoopingRandomSource implements RandomSource {
  _LoopingRandomSource(this.values);

  final List<int> values;
  int _index = 0;

  @override
  int nextInt(int max) {
    final int value = values[_index % values.length];
    _index += 1;

    if (value >= max) {
      return value % max;
    }

    return value;
  }
}

class _FixedRandomSource implements RandomSource {
  _FixedRandomSource(this.value);

  final int value;

  @override
  int nextInt(int max) => value % max;
}
