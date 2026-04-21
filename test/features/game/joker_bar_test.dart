import 'package:crush_word/src/core/config/game_rules_config.dart';
import 'package:crush_word/src/features/game/widgets/joker_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('joker bar renders all jokers with xN counters', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: JokerBar(
            jokers: _jokers,
            inventoryById: const <String, int>{'fish': 2, 'wheel': 1},
            onJokerPressed: (_) {},
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('joker-bar-fish')), findsOneWidget);
    expect(find.byKey(const Key('joker-bar-wheel')), findsOneWidget);
    expect(find.byKey(const Key('joker-bar-party_booster')), findsOneWidget);
    expect(find.text('x2'), findsOneWidget);
    expect(find.text('x1'), findsOneWidget);
    expect(find.text('x0'), findsOneWidget);
  });

  testWidgets('joker bar forwards presses and marks the active joker', (
    WidgetTester tester,
  ) async {
    String? pressedJokerId;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: JokerBar(
            jokers: _jokers.take(2).toList(growable: false),
            inventoryById: const <String, int>{'fish': 2, 'wheel': 1},
            activeJokerId: 'wheel',
            helperText: 'Tekerlek hazır',
            onJokerPressed: (String jokerId) {
              pressedJokerId = jokerId;
            },
          ),
        ),
      ),
    );

    expect(find.text('Tekerlek hazır'), findsOneWidget);

    await tester.tap(find.byKey(const Key('joker-bar-wheel')));
    await tester.pumpAndSettle();

    expect(pressedJokerId, 'wheel');
  });

  testWidgets('joker with x0 is visible but disabled', (
    WidgetTester tester,
  ) async {
    String? pressedJokerId;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: JokerBar(
            jokers: _jokers,
            inventoryById: const <String, int>{'fish': 2, 'wheel': 0},
            onJokerPressed: (String jokerId) {
              pressedJokerId = jokerId;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('joker-bar-wheel')));
    await tester.pumpAndSettle();

    expect(find.text('x0'), findsNWidgets(2));
    expect(pressedJokerId, isNull);
  });
}

const List<MarketJokerDefinition> _jokers = <MarketJokerDefinition>[
  MarketJokerDefinition(
    id: 'fish',
    name: 'Balık',
    cost: 100,
    description: 'Balık açıklama',
    purpose: 'Balık amaç',
    usage: 'Balık kullanım',
  ),
  MarketJokerDefinition(
    id: 'wheel',
    name: 'Tekerlek',
    cost: 200,
    description: 'Tekerlek açıklama',
    purpose: 'Tekerlek amaç',
    usage: 'Tekerlek kullanım',
  ),
  MarketJokerDefinition(
    id: 'party_booster',
    name: 'Parti Güçlendiricisi',
    cost: 400,
    description: 'Parti açıklama',
    purpose: 'Parti amaç',
    usage: 'Parti kullanım',
  ),
];
