import 'package:crush_word/src/core/models/game_config.dart';
import 'package:crush_word/src/core/models/game_difficulty.dart';
import 'package:crush_word/src/core/models/game_result.dart';
import 'package:crush_word/src/core/persistence/sqlite/app_database.dart';
import 'package:sqflite/sqflite.dart';

class GameHistoryRepository {
  GameHistoryRepository({AppDatabase? database})
    : _database = database ?? AppDatabase();

  final AppDatabase _database;

  Future<void> saveResult(GameResult result) async {
    final Database database = await _database.database;

    await database.insert(
      'game_results',
      _mapResultToRow(result),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<List<GameResult>> loadResultsNewestFirst() async {
    final Database database = await _database.database;
    final List<Map<String, Object?>> rows = await database.query(
      'game_results',
      orderBy: 'completed_at DESC, id DESC',
    );

    return rows
        .map((Map<String, Object?> row) => _mapRowToResult(row))
        .toList(growable: false);
  }

  Map<String, Object?> _mapResultToRow(GameResult result) {
    return <String, Object?>{
      'id': result.id,
      'completed_at': result.completedAt.toIso8601String(),
      'difficulty': result.config.difficulty.name,
      'grid_size': result.config.gridSize,
      'starting_moves': result.config.moveLimit,
      'score': result.score,
      'words_found_count': result.wordsFoundCount,
      'longest_word': result.longestWord,
      'duration_seconds': result.duration.inSeconds,
    };
  }

  GameResult _mapRowToResult(Map<String, Object?> row) {
    final GameDifficulty difficulty = GameDifficulty.fromName(
      row['difficulty'] as String,
    );

    return GameResult(
      id: row['id'] as String,
      config: GameConfig(
        difficulty: difficulty,
        difficultyLabel: _difficultyLabelFor(difficulty),
        gridSize: (row['grid_size'] as num).toInt(),
        moveLimit: (row['starting_moves'] as num).toInt(),
      ),
      score: (row['score'] as num).toInt(),
      wordsFoundCount: (row['words_found_count'] as num).toInt(),
      longestWord: (row['longest_word'] as String?)?.trim() ?? '',
      duration: Duration(
        seconds: (row['duration_seconds'] as num).toInt(),
      ),
      completedAt: DateTime.parse(row['completed_at'] as String),
    );
  }

  String _difficultyLabelFor(GameDifficulty difficulty) {
    return switch (difficulty) {
      GameDifficulty.easy => 'Kolay',
      GameDifficulty.medium => 'Orta',
      GameDifficulty.hard => 'Zor',
    };
  }
}
