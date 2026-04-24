import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:crush_word/src/features/game/widgets/game_header.dart';

void main() {
  testWidgets('header shows move count text instead of difficulty/grid info', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GameHeader(
            score: 0,
            movesLeft: 15,
            activeWord: '',
            compact: false,
            playableWordCount: 3,
          ),
        ),
      ),
    );

    expect(find.text('15 hamle'), findsOneWidget);
    expect(find.text('Zor'), findsNothing);
    expect(find.text('6×6'), findsNothing);
    expect(find.text('0000'), findsOneWidget);
    expect(find.byKey(const Key('game-combo-display')), findsOneWidget);
    expect(find.text('x1'), findsOneWidget);
  });

  testWidgets('header score is zero-padded and grows as score increases', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GameHeader(
            score: 7,
            movesLeft: 12,
            activeWord: '',
            compact: false,
            playableWordCount: 1,
          ),
        ),
      ),
    );

    expect(find.text('0007'), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GameHeader(
            score: 125,
            movesLeft: 11,
            activeWord: '',
            compact: false,
            playableWordCount: 1,
            lastWordScore: 118,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('0125'), findsOneWidget);
  });

  testWidgets('score pill shows combo multiplier under score', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GameHeader(
            score: 180,
            movesLeft: 8,
            activeWord: '',
            compact: false,
            comboCount: 4,
            playableWordCount: 2,
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('game-combo-display')), findsOneWidget);
    expect(find.text('x4'), findsOneWidget);
  });

  testWidgets('score uses digital monospace styling', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GameHeader(
            score: 42,
            movesLeft: 9,
            activeWord: '',
            compact: false,
            playableWordCount: 2,
          ),
        ),
      ),
    );

    final Text scoreText = tester.widget<Text>(
      find.byKey(const Key('game-score-display')),
    );

    expect(scoreText.data, '0042');
    expect(scoreText.style?.fontFamily, 'monospace');
    expect(scoreText.style?.letterSpacing, 2.8);
  });
}
