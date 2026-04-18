import 'package:crush_word/src/core/config/game_rules_config.dart';
import 'package:crush_word/src/core/gameplay/models/board_cell.dart';
import 'package:crush_word/src/core/gameplay/models/game_session.dart';
import 'package:crush_word/src/core/gameplay/services/scoring_engine.dart';
import 'package:crush_word/src/core/gameplay/services/word_validator.dart';
import 'package:crush_word/src/core/models/game_config.dart';
import 'package:crush_word/src/core/models/game_difficulty.dart';
import 'package:crush_word/src/core/models/game_result.dart';
import 'package:crush_word/src/core/persistence/sqlite/app_database.dart';
import 'package:crush_word/src/core/repositories/dictionary_repository.dart';
import 'package:crush_word/src/core/repositories/game_history_repository.dart';
import 'package:crush_word/src/core/repositories/session_checkpoint_repository.dart';
import 'package:crush_word/src/features/game/game_controller.dart';
import 'package:crush_word/src/features/game/game_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Endgame persistence', () {
    late AppDatabase database;
    late GameHistoryRepository gameHistoryRepository;
    late SessionCheckpointRepository checkpointRepository;
    late DateTime fixedNow;

    setUp(() {
      sqfliteFfiInit();
      fixedNow = DateTime(2026, 4, 18, 16, 30, 0);
      database = AppDatabase(
        databaseFactory: databaseFactoryFfi,
        databasePath: inMemoryDatabasePath,
      );
      gameHistoryRepository = GameHistoryRepository(database: database);
      checkpointRepository = SessionCheckpointRepository(
        database: database,
        clock: () => fixedNow,
      );
    });

    tearDown(() async {
      await database.close();
    });

    test(
      'move depletion saves once, clears checkpoint and stays newest-first',
      () async {
        await gameHistoryRepository.saveResult(
          GameResult(
            id: 'older-result',
            config: const GameConfig(
              difficulty: GameDifficulty.medium,
              difficultyLabel: 'Orta',
              gridSize: 8,
              moveLimit: 20,
            ),
            score: 12,
            wordsFoundCount: 2,
            longestWord: 'kale',
            duration: const Duration(minutes: 1),
            completedAt: fixedNow.subtract(const Duration(days: 1)),
          ),
        );

        final GameSession session = _buildSession(
          letters: const <String>['B', 'A', 'L', 'X', 'Y', 'Z', 'W', 'Q', 'P'],
          movesLeft: 1,
          score: 0,
          startedAt: fixedNow.subtract(
            const Duration(minutes: 2, seconds: 15),
          ),
        );

        final GameController controller = GameController.fromSession(
          session,
          wordValidator: _buildValidator(const <String>{'bal'}),
          scoringEngine: ScoringEngine(
            scoringConfig: ScoringConfig(
              letterScores: const <String, int>{
                'B': 4,
                'A': 1,
                'L': 2,
              },
            ),
          ),
          gameHistoryRepository: gameHistoryRepository,
          sessionCheckpointRepository: checkpointRepository,
          clock: () => fixedNow,
        );

        await controller.load();
        expect(await checkpointRepository.load(), isNotNull);

        controller.startSelection(session.cellAt(row: 0, column: 0));
        controller.extendSelection(session.cellAt(row: 0, column: 1));
        controller.extendSelection(session.cellAt(row: 0, column: 2));

        await controller.endSelection();

        final List<GameResult> results =
            await gameHistoryRepository.loadResultsNewestFirst();
        expect(results, hasLength(2));
        expect(results.first.id, isNot('older-result'));
        expect(results.first.score, 7);
        expect(results.first.wordsFoundCount, 1);
        expect(results.first.longestWord, 'bal');
        expect(
          results.first.duration,
          const Duration(minutes: 2, seconds: 15),
        );
        expect(await checkpointRepository.load(), isNull);

        await controller.confirmExit();
        expect(
          await gameHistoryRepository.loadResultsNewestFirst(),
          hasLength(2),
        );
      },
    );
  });

  testWidgets(
    'back exit shows confirmation and only saves on evet',
    (WidgetTester tester) async {
      final DateTime fixedNow = DateTime(2026, 4, 18, 17, 15, 0);
      final MemoryGameHistoryRepository gameHistoryRepository =
          MemoryGameHistoryRepository();
      final MemorySessionCheckpointRepository checkpointRepository =
          MemorySessionCheckpointRepository();

      final GameSession session = _buildSession(
        letters: const <String>['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I'],
        movesLeft: 5,
        score: 11,
        startedAt: fixedNow.subtract(const Duration(seconds: 45)),
      );

      final GameController controller = GameController.fromSession(
        session,
        gameHistoryRepository: gameHistoryRepository,
        sessionCheckpointRepository: checkpointRepository,
        clock: () => fixedNow,
      );

      await tester.pumpWidget(_buildTestApp(controller));
      await tester.pump();
      await tester.tap(find.text('Oyunu Aç'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(await checkpointRepository.load(), isNotNull);

      await tester.pageBack();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Oyundan çıkılsın mı?'), findsOneWidget);

      await tester.tap(find.text('Hayır'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('home screen'), findsNothing);
      expect(await gameHistoryRepository.loadResultsNewestFirst(), isEmpty);
      expect(await checkpointRepository.load(), isNotNull);

      await tester.pageBack();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Evet'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final List<GameResult> results =
          await gameHistoryRepository.loadResultsNewestFirst();
      expect(results, hasLength(1));
      expect(results.single.score, 11);
      expect(results.single.wordsFoundCount, 0);
      expect(results.single.longestWord, isEmpty);
      expect(results.single.duration, const Duration(seconds: 45));
      expect(await checkpointRepository.load(), isNull);
      expect(find.text('home screen'), findsOneWidget);
    },
  );
}

Widget _buildTestApp(GameController controller) {
  return MaterialApp(
    home: _GameHost(controller: controller),
  );
}

class _GameHost extends StatelessWidget {
  const _GameHost({required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text('home screen'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => GameScreen(
                      config: controller.config,
                      controller: controller,
                    ),
                  ),
                );
              },
              child: const Text('Oyunu Aç'),
            ),
          ],
        ),
      ),
    );
  }
}

class MemoryGameHistoryRepository extends GameHistoryRepository {
  final List<GameResult> _results = <GameResult>[];

  @override
  Future<void> saveResult(GameResult result) async {
    if (_results.any((GameResult item) => item.id == result.id)) {
      return;
    }

    _results.add(result);
  }

  @override
  Future<List<GameResult>> loadResultsNewestFirst() async {
    final List<GameResult> copy = List<GameResult>.from(_results);
    copy.sort(
      (GameResult left, GameResult right) =>
          right.completedAt.compareTo(left.completedAt),
    );
    return copy;
  }
}

class MemorySessionCheckpointRepository extends SessionCheckpointRepository {
  GameSession? _session;

  @override
  Future<void> save(GameSession session) async {
    _session = session;
  }

  @override
  Future<GameSession?> load() async {
    return _session;
  }

  @override
  Future<void> clear() async {
    _session = null;
  }
}

WordValidator _buildValidator(Set<String> words) {
  return WordValidator(
    dictionaryRepository: DictionaryRepository(
      assetLoader: (_) async => words.join('\n'),
    ),
  );
}

GameSession _buildSession({
  required List<String> letters,
  required int movesLeft,
  required int score,
  required DateTime startedAt,
}) {
  return GameSession(
    config: const GameConfig(
      difficulty: GameDifficulty.hard,
      difficultyLabel: 'Zor',
      gridSize: 3,
      moveLimit: 15,
    ),
    board: List<BoardCell>.generate(
      letters.length,
      (int index) => BoardCell(
        row: index ~/ 3,
        column: index % 3,
        letter: letters[index],
      ),
      growable: false,
    ),
    movesLeft: movesLeft,
    score: score,
    startedAt: startedAt,
  );
}
