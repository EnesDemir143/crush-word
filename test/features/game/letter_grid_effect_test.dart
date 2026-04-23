import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:crush_word/src/core/gameplay/models/board_cell.dart';
import 'package:crush_word/src/core/gameplay/models/game_session.dart';
import 'package:crush_word/src/core/gameplay/services/joker_engine.dart';
import 'package:crush_word/src/core/models/game_config.dart';
import 'package:crush_word/src/core/models/game_difficulty.dart';
import 'package:crush_word/src/features/game/widgets/letter_grid.dart';

void main() {
  testWidgets(
    'lollipop breaker launches candy from joker source into target cell',
    (WidgetTester tester) async {
      final GameSession session = _buildSession();
      final GlobalKey sourceKey = GlobalKey(debugLabel: 'test-lollipop-source');

      await tester.pumpWidget(
        _gridHarness(session: session, sourceKey: sourceKey),
      );
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        _gridHarness(
          session: session,
          sourceKey: sourceKey,
          effectToken: 1,
          lastRemovedCellIds: const <String>['0:2'],
          lastJokerEffectId: JokerIds.lollipopBreaker,
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('lollipop-strike-candy')), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pump(const Duration(milliseconds: 520));

      expect(find.byKey(const Key('lollipop-strike-candy')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

Widget _gridHarness({
  required GameSession session,
  int effectToken = 0,
  List<String> lastRemovedCellIds = const <String>[],
  String? lastJokerEffectId,
  GlobalKey? sourceKey,
}) {
  return MaterialApp(
    home: Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          SizedBox(
            width: 72,
            height: 72,
            child: DecoratedBox(
              key: sourceKey,
              decoration: const BoxDecoration(shape: BoxShape.circle),
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: SizedBox.square(
              dimension: 320,
              child: LetterGrid(
                session: session,
                selectedCellIds: const <String>[],
                onSelectionStart: (_) {},
                onSelectionExtend: (_) {},
                lastRemovedCellIds: lastRemovedCellIds,
                effectToken: effectToken,
                lastJokerEffectId: lastJokerEffectId,
                lollipopSourceKey: sourceKey,
              ),
            ),
          ),
        ],
      ),
    ),
  );
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
