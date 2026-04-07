import 'package:crush_word/src/core/models/game_config.dart';

class GameResult {
  GameResult({
    required this.id,
    required this.config,
    required this.score,
    required this.wordsFoundCount,
    required this.longestWord,
    required this.duration,
    required this.completedAt,
  }) : assert(score >= 0, 'Score cannot be negative.'),
       assert(wordsFoundCount >= 0, 'Word count cannot be negative.'),
       assert(!duration.isNegative, 'Duration cannot be negative.');

  final String id;
  final GameConfig config;
  final int score;
  final int wordsFoundCount;
  final String longestWord;
  final Duration duration;
  final DateTime completedAt;

  GameResult copyWith({
    String? id,
    GameConfig? config,
    int? score,
    int? wordsFoundCount,
    String? longestWord,
    Duration? duration,
    DateTime? completedAt,
  }) {
    return GameResult(
      id: id ?? this.id,
      config: config ?? this.config,
      score: score ?? this.score,
      wordsFoundCount: wordsFoundCount ?? this.wordsFoundCount,
      longestWord: longestWord ?? this.longestWord,
      duration: duration ?? this.duration,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'config': config.toJson(),
      'score': score,
      'wordsFoundCount': wordsFoundCount,
      'longestWord': longestWord,
      'durationSeconds': duration.inSeconds,
      'completedAt': completedAt.toIso8601String(),
    };
  }

  factory GameResult.fromJson(Map<String, dynamic> json) {
    return GameResult(
      id: json['id'] as String,
      config: GameConfig.fromJson(json['config'] as Map<String, dynamic>),
      score: (json['score'] as num).toInt(),
      wordsFoundCount: (json['wordsFoundCount'] as num).toInt(),
      longestWord: (json['longestWord'] as String?)?.trim() ?? '',
      duration: Duration(
        seconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
      ),
      completedAt: DateTime.parse(json['completedAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is GameResult &&
        other.id == id &&
        other.config == config &&
        other.score == score &&
        other.wordsFoundCount == wordsFoundCount &&
        other.longestWord == longestWord &&
        other.duration == duration &&
        other.completedAt == completedAt;
  }

  @override
  int get hashCode => Object.hash(
    id,
    config,
    score,
    wordsFoundCount,
    longestWord,
    duration,
    completedAt,
  );
}
