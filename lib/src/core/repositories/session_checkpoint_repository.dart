import 'dart:convert';

import 'package:crush_word/src/core/gameplay/models/board_cell.dart';
import 'package:crush_word/src/core/gameplay/models/game_session.dart';
import 'package:crush_word/src/core/models/game_config.dart';
import 'package:crush_word/src/core/persistence/sqlite/app_database.dart';
import 'package:sqflite/sqflite.dart';

class SessionCheckpointRepository {
  SessionCheckpointRepository({
    AppDatabase? database,
    DateTime Function()? clock,
  }) : _database = database ?? AppDatabase(),
       _clock = clock ?? DateTime.now;

  static const String activeCheckpointId = 'active_session';

  final AppDatabase _database;
  final DateTime Function() _clock;

  Future<void> save(GameSession session) async {
    final Database database = await _database.database;
    final DateTime now = _clock();
    final int elapsedSeconds = _elapsedSecondsFor(
      session: session,
      now: now,
    );

    await database.insert(
      'session_checkpoint',
      <String, Object?>{
        'checkpoint_id': activeCheckpointId,
        'game_config_json': jsonEncode(session.config.toJson()),
        'board_json': jsonEncode(
          session.board
              .map((BoardCell cell) => cell.toJson())
              .toList(growable: false),
        ),
        'remaining_moves': session.movesLeft,
        'elapsed_seconds': elapsedSeconds,
        'current_score': session.score,
        'words_found_count': session.wordsFoundCount,
        'longest_word': session.longestWord,
        'selected_path_json': jsonEncode(session.selectedCellIds),
        'power_tiles_json': jsonEncode(
          session.board
              .where((BoardCell cell) => cell.power != null)
              .map((BoardCell cell) => cell.toJson())
              .toList(growable: false),
        ),
        'updated_at': now.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<GameSession?> load() async {
    final Database database = await _database.database;
    final List<Map<String, Object?>> rows = await database.query(
      'session_checkpoint',
      where: 'checkpoint_id = ?',
      whereArgs: <Object>[activeCheckpointId],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    final Map<String, Object?> row = rows.single;
    final int elapsedSeconds =
        (row['elapsed_seconds'] as num?)?.toInt() ?? 0;

    return GameSession(
      config: GameConfig.fromJson(
        _decodeJsonObject(row['game_config_json'] as String),
      ),
      board: _decodeJsonList(row['board_json'] as String)
          .map((Object? cellJson) {
            return BoardCell.fromJson(
              Map<String, dynamic>.from(cellJson! as Map<dynamic, dynamic>),
            );
          })
          .toList(growable: false),
      movesLeft: (row['remaining_moves'] as num).toInt(),
      score: (row['current_score'] as num?)?.toInt() ?? 0,
      wordsFoundCount: (row['words_found_count'] as num?)?.toInt() ?? 0,
      longestWord: (row['longest_word'] as String?)?.trim() ?? '',
      startedAt: _clock().subtract(Duration(seconds: elapsedSeconds)),
      selectedCellIds: _decodeJsonList(row['selected_path_json'] as String)
          .map((Object? value) => (value as String?)?.trim() ?? '')
          .where((String value) => value.isNotEmpty)
          .toList(growable: false),
    );
  }

  Future<void> clear() async {
    final Database database = await _database.database;
    await database.delete(
      'session_checkpoint',
      where: 'checkpoint_id = ?',
      whereArgs: <Object>[activeCheckpointId],
    );
  }

  int _elapsedSecondsFor({
    required GameSession session,
    required DateTime now,
  }) {
    final int elapsedSeconds = now.difference(session.startedAt).inSeconds;
    return elapsedSeconds < 0 ? 0 : elapsedSeconds;
  }

  Map<String, dynamic> _decodeJsonObject(String rawJson) {
    return Map<String, dynamic>.from(
      jsonDecode(rawJson) as Map<dynamic, dynamic>,
    );
  }

  List<dynamic> _decodeJsonList(String rawJson) {
    return List<dynamic>.from(jsonDecode(rawJson) as List<dynamic>);
  }
}
