import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:crush_word/src/core/gameplay/models/board_cell.dart';
import 'package:crush_word/src/core/gameplay/models/game_session.dart';
import 'package:crush_word/src/core/models/game_config.dart';
import 'package:crush_word/src/core/models/game_difficulty.dart';
import 'package:crush_word/src/features/game/game_controller.dart';
import 'package:crush_word/src/features/game/game_screen.dart';

void main() {
  testWidgets('game board renders the full square session grid', (
    WidgetTester tester,
  ) async {
    final GameSession session = _buildSession(gridSize: 3);
    final GameController controller = GameController.fromSession(session);

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
    final GameController controller = GameController.fromSession(session);

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

  testWidgets('dragging only keeps adjacent cells in the active path', (
    WidgetTester tester,
  ) async {
    final GameSession session = _buildSession(gridSize: 3);
    final GameController controller = GameController.fromSession(session);

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

    await gesture.up();

    expect(controller.selectedCellIds, <String>['0:0', '0:1']);
    expect(controller.selectedWord, 'AB');
  });

  test('an already selected cell cannot be re-added to the path', () {
    final GameSession session = _buildSession(gridSize: 3);
    final GameController controller = GameController.fromSession(session);

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
