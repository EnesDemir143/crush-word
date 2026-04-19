import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:crush_word/src/core/models/game_config.dart';
import 'package:crush_word/src/core/models/game_difficulty.dart';
import 'package:crush_word/src/core/models/game_result.dart';
import 'package:crush_word/src/core/repositories/game_history_repository.dart';
import 'package:crush_word/src/features/score_history/history_controller.dart';
import 'package:crush_word/src/features/score_history/score_history_screen.dart';

void main() {
  late HistoryController controller;
  late _FakeGameHistoryRepository repository;

  setUp(() {
    repository = _FakeGameHistoryRepository();
    controller = HistoryController(repository: repository);
  });

  tearDown(() {
    controller.dispose();
  });

  group('empty state', () {
    testWidgets('shows empty message when no results exist', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(home: ScoreHistoryScreen(controller: controller)),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('history-empty')), findsOneWidget);
    });
  });

  group('with saved results', () {
    final List<GameResult> testResults = <GameResult>[
      GameResult(
        id: 'game-3',
        config: const GameConfig(
          difficulty: GameDifficulty.hard,
          difficultyLabel: 'Zor',
          gridSize: 6,
          moveLimit: 15,
        ),
        score: 320,
        wordsFoundCount: 8,
        longestWord: 'KALEM',
        duration: const Duration(minutes: 5, seconds: 30),
        completedAt: DateTime(2026, 4, 19, 14, 30),
      ),
      GameResult(
        id: 'game-2',
        config: const GameConfig(
          difficulty: GameDifficulty.medium,
          difficultyLabel: 'Orta',
          gridSize: 5,
          moveLimit: 20,
        ),
        score: 210,
        wordsFoundCount: 6,
        longestWord: 'ARABA',
        duration: const Duration(minutes: 4, seconds: 15),
        completedAt: DateTime(2026, 4, 18, 10, 0),
      ),
      GameResult(
        id: 'game-1',
        config: const GameConfig(
          difficulty: GameDifficulty.easy,
          difficultyLabel: 'Kolay',
          gridSize: 4,
          moveLimit: 25,
        ),
        score: 150,
        wordsFoundCount: 4,
        longestWord: 'EV',
        duration: const Duration(minutes: 3),
        completedAt: DateTime(2026, 4, 17, 8, 0),
      ),
    ];

    testWidgets('renders newest-first game cards with required fields', (
      WidgetTester tester,
    ) async {
      repository.results = testResults;

      await tester.binding.setSurfaceSize(const Size(430, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(home: ScoreHistoryScreen(controller: controller)),
      );
      await tester.pumpAndSettle();

      // Summary section is present
      expect(find.byKey(const Key('history-summary')), findsOneWidget);

      // All three game cards are present
      expect(find.byKey(const Key('history-card-game-3')), findsOneWidget);
      expect(find.byKey(const Key('history-card-game-2')), findsOneWidget);
      expect(find.byKey(const Key('history-card-game-1')), findsOneWidget);

      // Newest card (#3) appears before oldest (#1)
      final double card3Y = tester
          .getTopLeft(find.byKey(const Key('history-card-game-3')))
          .dy;
      final double card1Y = tester
          .getTopLeft(find.byKey(const Key('history-card-game-1')))
          .dy;
      expect(
        card3Y,
        lessThan(card1Y),
        reason: 'The newest game must appear above the oldest',
      );

      // Scores on cards
      expect(find.text('320'), findsWidgets);
      expect(find.text('210'), findsWidgets);
      expect(find.text('150'), findsWidgets);

      // Grid sizes
      expect(find.text('6x6'), findsWidgets);
      expect(find.text('5x5'), findsWidgets);
      expect(find.text('4x4'), findsWidgets);

      // Move counts
      expect(find.text('15 hamle'), findsOneWidget);
      expect(find.text('20 hamle'), findsOneWidget);
      expect(find.text('25 hamle'), findsOneWidget);

      // Word counts
      expect(find.text('8 kelime'), findsOneWidget);
      expect(find.text('6 kelime'), findsOneWidget);
      expect(find.text('4 kelime'), findsOneWidget);

      // Longest words
      expect(find.text('KALEM'), findsWidgets);
      expect(find.text('ARABA'), findsWidgets);

      // Durations
      expect(find.text('5dk 30sn'), findsOneWidget);
      expect(find.text('4dk 15sn'), findsOneWidget);
      expect(find.text('3dk 0sn'), findsOneWidget);

      // Dates in dd.MM.yyyy HH:mm format
      expect(find.text('19.04.2026  14:30'), findsOneWidget);
      expect(find.text('18.04.2026  10:00'), findsOneWidget);
      expect(find.text('17.04.2026  08:00'), findsOneWidget);
    });

    testWidgets('summary section shows correct aggregate metrics', (
      WidgetTester tester,
    ) async {
      repository.results = testResults;

      await tester.binding.setSurfaceSize(const Size(430, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(home: ScoreHistoryScreen(controller: controller)),
      );
      await tester.pumpAndSettle();

      // Total games = 3
      expect(
        find.descendant(
          of: find.byKey(const Key('summary-total-games')),
          matching: find.text('3'),
        ),
        findsOneWidget,
      );

      // High score = 320
      expect(
        find.descendant(
          of: find.byKey(const Key('summary-high-score')),
          matching: find.text('320'),
        ),
        findsOneWidget,
      );

      // Average score = (320+210+150) ~/ 3 = 226
      expect(
        find.descendant(
          of: find.byKey(const Key('summary-avg-score')),
          matching: find.text('226'),
        ),
        findsOneWidget,
      );

      // Total words = 8+6+4 = 18
      expect(
        find.descendant(
          of: find.byKey(const Key('summary-total-words')),
          matching: find.text('18'),
        ),
        findsOneWidget,
      );

      // Longest word = KALEM (5 chars)
      expect(
        find.descendant(
          of: find.byKey(const Key('summary-longest-word')),
          matching: find.text('KALEM'),
        ),
        findsOneWidget,
      );

      // Total duration = 5:30+4:15+3:00 = 12dk 45sn
      expect(
        find.descendant(
          of: find.byKey(const Key('summary-total-duration')),
          matching: find.text('12dk 45sn'),
        ),
        findsOneWidget,
      );
    });
  });
}

/// Fake repository that returns in-memory results.
class _FakeGameHistoryRepository extends GameHistoryRepository {
  List<GameResult> results = <GameResult>[];

  @override
  Future<List<GameResult>> loadResultsNewestFirst() async {
    return results;
  }
}
