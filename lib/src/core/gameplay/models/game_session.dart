import 'package:flutter/foundation.dart';

import 'package:crush_word/src/core/gameplay/models/board_cell.dart';
import 'package:crush_word/src/core/models/game_config.dart';

class GameSession {
  GameSession({
    required this.config,
    required List<BoardCell> board,
    required this.movesLeft,
    this.score = 0,
    this.wordsFoundCount = 0,
    this.longestWord = '',
    this.playableWordCount = 0,
    DateTime? startedAt,
    List<String> selectedCellIds = const <String>[],
    Map<String, int> jokerInventory = const <String, int>{},
  }) : board = List<BoardCell>.unmodifiable(board),
       startedAt = startedAt ?? DateTime.now(),
       selectedCellIds = List<String>.unmodifiable(selectedCellIds),
       jokerInventory = Map<String, int>.unmodifiable(jokerInventory) {
    final int expectedCellCount = config.gridSize * config.gridSize;

    if (this.board.length != expectedCellCount) {
      throw ArgumentError.value(
        this.board.length,
        'board.length',
        'GameSession board must contain exactly $expectedCellCount cells.',
      );
    }
  }

  final GameConfig config;
  final List<BoardCell> board;
  final int movesLeft;
  final int score;
  final int wordsFoundCount;
  final String longestWord;

  /// Number of non-overlapping valid words currently on the board.
  final int playableWordCount;
  final DateTime startedAt;
  final List<String> selectedCellIds;
  final Map<String, int> jokerInventory;

  int get gridSize => config.gridSize;

  List<List<BoardCell>> get rows => List<List<BoardCell>>.generate(
    gridSize,
    (int rowIndex) => List<BoardCell>.unmodifiable(
      board.skip(rowIndex * gridSize).take(gridSize),
    ),
    growable: false,
  );

  BoardCell cellAt({required int row, required int column}) {
    return board.firstWhere(
      (BoardCell cell) => cell.row == row && cell.column == column,
    );
  }

  GameSession copyWith({
    GameConfig? config,
    List<BoardCell>? board,
    int? movesLeft,
    int? score,
    int? wordsFoundCount,
    String? longestWord,
    int? playableWordCount,
    DateTime? startedAt,
    List<String>? selectedCellIds,
    Map<String, int>? jokerInventory,
  }) {
    return GameSession(
      config: config ?? this.config,
      board: board ?? this.board,
      movesLeft: movesLeft ?? this.movesLeft,
      score: score ?? this.score,
      wordsFoundCount: wordsFoundCount ?? this.wordsFoundCount,
      longestWord: longestWord ?? this.longestWord,
      playableWordCount: playableWordCount ?? this.playableWordCount,
      startedAt: startedAt ?? this.startedAt,
      selectedCellIds: selectedCellIds ?? this.selectedCellIds,
      jokerInventory: jokerInventory ?? this.jokerInventory,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'config': config.toJson(),
      'board': board.map((BoardCell cell) => cell.toJson()).toList(),
      'movesLeft': movesLeft,
      'score': score,
      'wordsFoundCount': wordsFoundCount,
      'longestWord': longestWord,
      'playableWordCount': playableWordCount,
      'startedAt': startedAt.toIso8601String(),
      'selectedCellIds': selectedCellIds,
      'jokerInventory': jokerInventory,
    };
  }

  factory GameSession.fromJson(Map<String, dynamic> json) {
    final Object? configJson = json['config'];
    final Object? boardJson = json['board'];
    final int? movesLeft = (json['movesLeft'] as num?)?.toInt();
    final int score = (json['score'] as num?)?.toInt() ?? 0;
    final int wordsFoundCount = (json['wordsFoundCount'] as num?)?.toInt() ?? 0;
    final String longestWord = (json['longestWord'] as String?)?.trim() ?? '';
    final int playableWordCount =
        (json['playableWordCount'] as num?)?.toInt() ?? 0;
    final String? startedAtRaw = json['startedAt'] as String?;
    final Object? selectedCellIdsJson = json['selectedCellIds'];
    final Object? jokerInventoryJson = json['jokerInventory'];

    if (configJson is! Map<String, dynamic> || boardJson is! List<dynamic>) {
      throw const FormatException(
        'GameSession requires config and board values.',
      );
    }

    if (movesLeft == null) {
      throw const FormatException('GameSession requires movesLeft.');
    }

    final List<BoardCell> board = boardJson
        .map((Object? cellJson) {
          if (cellJson is! Map<String, dynamic>) {
            throw const FormatException(
              'Each board cell must be a JSON object.',
            );
          }

          return BoardCell.fromJson(cellJson);
        })
        .toList(growable: false);

    final List<String> selectedCellIds = selectedCellIdsJson is List<dynamic>
        ? selectedCellIdsJson
              .map((Object? id) => (id as String?)?.trim() ?? '')
              .where((String id) => id.isNotEmpty)
              .toList(growable: false)
        : const <String>[];

    final Map<String, int> jokerInventory =
        jokerInventoryJson is Map<String, dynamic>
        ? jokerInventoryJson.map<String, int>((String key, dynamic value) {
            return MapEntry(key, (value as num).toInt());
          })
        : const <String, int>{};

    return GameSession(
      config: GameConfig.fromJson(configJson),
      board: board,
      movesLeft: movesLeft,
      score: score,
      wordsFoundCount: wordsFoundCount,
      longestWord: longestWord,
      playableWordCount: playableWordCount,
      startedAt: startedAtRaw == null || startedAtRaw.trim().isEmpty
          ? null
          : DateTime.parse(startedAtRaw),
      selectedCellIds: selectedCellIds,
      jokerInventory: jokerInventory,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is GameSession &&
        other.config == config &&
        listEquals(other.board, board) &&
        other.movesLeft == movesLeft &&
        other.score == score &&
        other.wordsFoundCount == wordsFoundCount &&
        other.longestWord == longestWord &&
        other.playableWordCount == playableWordCount &&
        other.startedAt == startedAt &&
        listEquals(other.selectedCellIds, selectedCellIds) &&
        mapEquals(other.jokerInventory, jokerInventory);
  }

  @override
  int get hashCode => Object.hash(
    config,
    Object.hashAll(board),
    movesLeft,
    score,
    wordsFoundCount,
    longestWord,
    playableWordCount,
    startedAt,
    Object.hashAll(selectedCellIds),
    Object.hashAll(
      jokerInventory.entries.map(
        (MapEntry<String, int> entry) => Object.hash(entry.key, entry.value),
      ),
    ),
  );
}
