import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:crush_word/src/core/config/game_rules_loader.dart';
import 'package:crush_word/src/core/models/game_config.dart';
import 'package:crush_word/src/core/models/game_difficulty.dart';
import 'package:crush_word/src/features/game_setup/game_setup_controller.dart';
import 'package:crush_word/src/features/game_setup/new_game_screen.dart';

void main() {
  testWidgets('setup UI only shows documented difficulty mappings', (
    WidgetTester tester,
  ) async {
    final GameSetupController controller = GameSetupController(
      loader: GameRulesLoader(bundle: _TestAssetBundle(_gameRulesJson)),
    );

    await tester.pumpWidget(
      MaterialApp(home: NewGameScreen(controller: controller)),
    );
    await tester.pumpAndSettle();

    expect(find.text('6x6 Grid'), findsOneWidget);
    expect(find.text('8x8 Grid'), findsOneWidget);
    expect(find.text('10x10 Grid'), findsOneWidget);
    expect(find.text('Zor'), findsOneWidget);
    expect(find.text('Orta'), findsOneWidget);
    expect(find.text('Kolay'), findsOneWidget);
    expect(find.text('12x12 Grid'), findsNothing);
  });

  testWidgets('move step only exposes the documented move count', (
    WidgetTester tester,
  ) async {
    final GameSetupController controller = GameSetupController(
      loader: GameRulesLoader(bundle: _TestAssetBundle(_gameRulesJson)),
    );

    await tester.pumpWidget(
      MaterialApp(home: NewGameScreen(controller: controller)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('setup-difficulty-hard')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('setup-move-15')), findsOneWidget);
    expect(find.byKey(const Key('setup-move-20')), findsOneWidget);
    expect(find.byKey(const Key('setup-move-25')), findsOneWidget);
  });

  testWidgets(
    'selecting an independent move count starts a structured game session config',
    (WidgetTester tester) async {
      final GameSetupController controller = GameSetupController(
        loader: GameRulesLoader(bundle: _TestAssetBundle(_gameRulesJson)),
      );
      GameConfig? startedConfig;

      await tester.pumpWidget(
        MaterialApp(
          home: NewGameScreen(
            controller: controller,
            onStartGame: (GameConfig config) {
              startedConfig = config;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('setup-difficulty-medium')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('setup-move-20')));
      await tester.pumpAndSettle();

      expect(
        startedConfig,
        const GameConfig(
          difficulty: GameDifficulty.medium,
          difficultyLabel: 'Orta',
          gridSize: 8,
          moveLimit: 20,
        ),
      );
    },
  );

  testWidgets(
    'selected grid stays fixed even when a different move package is chosen',
    (WidgetTester tester) async {
      final GameSetupController controller = GameSetupController(
        loader: GameRulesLoader(bundle: _TestAssetBundle(_gameRulesJson)),
      );
      GameConfig? startedConfig;

      await tester.pumpWidget(
        MaterialApp(
          home: NewGameScreen(
            controller: controller,
            onStartGame: (GameConfig config) {
              startedConfig = config;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('setup-difficulty-hard')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('setup-move-25')));
      await tester.pumpAndSettle();

      expect(
        startedConfig,
        const GameConfig(
          difficulty: GameDifficulty.hard,
          difficultyLabel: 'Zor',
          gridSize: 6,
          moveLimit: 25,
        ),
      );
    },
  );
}

class _TestAssetBundle extends CachingAssetBundle {
  _TestAssetBundle(this.gameRulesJson);

  final String gameRulesJson;

  @override
  Future<ByteData> load(String key) async {
    final Uint8List bytes = Uint8List.fromList(utf8.encode(gameRulesJson));
    return ByteData.view(bytes.buffer);
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    return gameRulesJson;
  }
}

const String _gameRulesJson = '''
{
  "setup": {
    "difficultyOptions": [
      {
        "difficulty": "hard",
        "label": "Zor",
        "gridLabel": "6x6 Grid",
        "gridSize": 6
      },
      {
        "difficulty": "medium",
        "label": "Orta",
        "gridLabel": "8x8 Grid",
        "gridSize": 8
      },
      {
        "difficulty": "easy",
        "label": "Kolay",
        "gridLabel": "10x10 Grid",
        "gridSize": 10
      }
    ],
    "moveCountOptions": [
      {
        "difficulty": "easy",
        "label": "Kolay",
        "moveLimit": 25
      },
      {
        "difficulty": "medium",
        "label": "Orta",
        "moveLimit": 20
      },
      {
        "difficulty": "hard",
        "label": "Zor",
        "moveLimit": 15
      }
    ]
  }
}
''';
