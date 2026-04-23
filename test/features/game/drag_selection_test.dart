import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:crush_word/src/core/config/game_rules_config.dart';
import 'package:crush_word/src/core/config/game_rules_loader.dart';
import 'package:crush_word/src/core/gameplay/models/board_cell.dart';
import 'package:crush_word/src/core/gameplay/models/game_session.dart';
import 'package:crush_word/src/core/models/game_config.dart';
import 'package:crush_word/src/core/models/game_difficulty.dart';
import 'package:crush_word/src/core/repositories/dictionary_repository.dart';
import 'package:crush_word/src/features/game/game_controller.dart';
import 'package:crush_word/src/features/game/game_screen.dart';
import 'package:flutter/services.dart';

import 'memory_session_checkpoint_repository.dart';

void main() {
  testWidgets('game board renders the full square session grid', (
    WidgetTester tester,
  ) async {
    final GameSession session = _buildSession(gridSize: 3);
    final GameController controller = GameController.fromSession(
      session,
      sessionCheckpointRepository: MemorySessionCheckpointRepository(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(config: session.config, controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('game-letter-grid')), findsOneWidget);
    expect(find.byKey(const Key('letter-cell-0:0')), findsOneWidget);
    expect(find.byKey(const Key('letter-cell-2:2')), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsNothing);
    expect(find.byType(Semantics), findsWidgets);
  });

  testWidgets('dense 10x10 board renders on a phone-sized surface', (
    WidgetTester tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(390, 844));

    final GameSession session = _buildSession(gridSize: 10);
    final GameController controller = GameController.fromSession(
      session,
      sessionCheckpointRepository: MemorySessionCheckpointRepository(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(config: session.config, controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('letter-cell-0:0')), findsOneWidget);
    expect(find.byKey(const Key('letter-cell-9:9')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('letter grid channel stays fixed while header expands', (
    WidgetTester tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(390, 844));

    final GameSession session = _buildSession(gridSize: 6);
    final GameController controller = GameController.fromSession(
      session,
      sessionCheckpointRepository: MemorySessionCheckpointRepository(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(config: session.config, controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    final Finder gridFinder = find.byKey(const Key('game-letter-grid'));
    final Rect initialGridRect = tester.getRect(gridFinder);

    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const Key('letter-cell-0:0'))),
    );
    await tester.pump();

    expect(controller.selectedWord, isNotEmpty);

    final Rect expandedHeaderGridRect = tester.getRect(gridFinder);
    expect(expandedHeaderGridRect.top, closeTo(initialGridRect.top, 0.1));
    expect(expandedHeaderGridRect.left, closeTo(initialGridRect.left, 0.1));
    expect(expandedHeaderGridRect.width, closeTo(initialGridRect.width, 0.1));
    expect(expandedHeaderGridRect.height, closeTo(initialGridRect.height, 0.1));

    await gesture.up();
  });

  testWidgets('active word path appends letters without moving the tracker', (
    WidgetTester tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(390, 844));

    final GameSession session = _buildSession(gridSize: 3);
    final GameController controller = GameController.fromSession(
      session,
      sessionCheckpointRepository: MemorySessionCheckpointRepository(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(config: session.config, controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const Key('letter-cell-0:0'))),
    );
    await tester.pump();

    final Finder activeWordFinder = find.byKey(
      const Key('active-word-path-text'),
    );

    expect(activeWordFinder, findsOneWidget);
    expect(tester.widget<Text>(activeWordFinder).data, 'A');
    await gesture.moveTo(
      tester.getCenter(find.byKey(const Key('letter-cell-0:1'))),
    );
    await tester.pump();

    expect(activeWordFinder, findsOneWidget);
    expect(tester.widget<Text>(activeWordFinder).data, 'AB');
    expect(tester.takeException(), isNull);

    await gesture.up();
  });

  testWidgets('header shows non-overlapping playable count', (
    WidgetTester tester,
  ) async {
    final GameSession session = _buildSessionFromRows(
      rows: const <List<String>>[
        <String>['k', 'a', 'l'],
        <String>['e', 'x', 'x'],
        <String>['x', 'x', 'x'],
      ],
      movesLeft: 10,
    );
    final GameController controller = GameController.fromSession(
      session,
      rulesLoader: _InMemoryRulesLoader(_testRules),
      dictionaryRepository: DictionaryRepository(
        assetLoader: (_) async => 'kal\nkale\n',
      ),
      sessionCheckpointRepository: MemorySessionCheckpointRepository(),
    );

    await controller.load();

    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(config: session.config, controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    // "kal" and "kale" overlap on the same path; visible count
    // must be non-overlapping and therefore 1.
    expect(controller.playableWordCount, 1);
    expect(find.byIcon(Icons.auto_stories_rounded), findsOneWidget);
    expect(find.text('1'), findsWidgets);
  });

  testWidgets('dragging only keeps adjacent cells in the active path', (
    WidgetTester tester,
  ) async {
    final GameSession session = _buildSession(gridSize: 3);
    final GameController controller = GameController.fromSession(
      session,
      sessionCheckpointRepository: MemorySessionCheckpointRepository(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(config: session.config, controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const Key('letter-cell-0:0'))),
    );

    await gesture.moveTo(
      tester.getCenter(find.byKey(const Key('letter-cell-0:1'))),
    );
    await tester.pump();

    await gesture.moveTo(
      tester.getCenter(find.byKey(const Key('letter-cell-2:2'))),
    );
    await tester.pump();

    // During drag: only adjacent cells should be in the path.
    expect(controller.selectedCellIds, <String>['0:0', '0:1']);
    expect(controller.selectedWord, 'AB');

    await gesture.up();
    await tester.pumpAndSettle();

    // After gesture up: endSelection finalizes and clears the path.
    expect(controller.selectedCellIds, isEmpty);
  });

  test('an already selected cell cannot be re-added to the path', () {
    final GameSession session = _buildSession(gridSize: 3);
    final GameController controller = GameController.fromSession(
      session,
      sessionCheckpointRepository: MemorySessionCheckpointRepository(),
    );

    controller.startSelection(session.cellAt(row: 0, column: 0));
    controller.extendSelection(session.cellAt(row: 0, column: 1));
    controller.extendSelection(session.cellAt(row: 1, column: 1));
    controller.extendSelection(session.cellAt(row: 0, column: 0));

    expect(controller.selectedCellIds, <String>['0:0', '0:1', '1:1']);
    expect(controller.selectedCellIds.toSet(), hasLength(3));
    expect(controller.selectedWord, 'ABE');
  });
}

GameSession _buildSession({required int gridSize}) {
  final GameConfig config = GameConfig(
    difficulty: GameDifficulty.medium,
    difficultyLabel: 'Orta',
    gridSize: gridSize,
    moveLimit: 20,
  );
  return GameSession(
    config: config,
    board: List<BoardCell>.generate(
      gridSize * gridSize,
      (int index) => BoardCell(
        row: index ~/ gridSize,
        column: index % gridSize,
        letter: _letterFor(index),
      ),
      growable: false,
    ),
    movesLeft: config.moveLimit,
  );
}

GameSession _buildSessionFromRows({
  required List<List<String>> rows,
  required int movesLeft,
}) {
  final int gridSize = rows.length;
  final List<String> letters = rows.expand((List<String> row) => row).toList();

  final GameConfig config = GameConfig(
    difficulty: GameDifficulty.medium,
    difficultyLabel: 'Orta',
    gridSize: gridSize,
    moveLimit: movesLeft,
  );

  return GameSession(
    config: config,
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

String _letterFor(int index) {
  const List<String> letters = <String>[
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
    'H',
    'I',
    'J',
    'K',
    'L',
    'M',
    'N',
    'O',
    'P',
    'R',
    'S',
    'T',
    'U',
    'V',
    'Y',
    'Z',
  ];

  return letters[index % letters.length];
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

const GameRulesConfig _testRules = GameRulesConfig(
  setup: GameSetupRules(
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
  boardGeneration: GameBoardGenerationRules(
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
);
