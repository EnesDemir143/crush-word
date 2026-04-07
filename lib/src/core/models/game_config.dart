import 'package:crush_word/src/core/models/game_difficulty.dart';

class GameConfig {
  const GameConfig({required this.difficulty});

  final GameDifficulty difficulty;

  int get gridSize => difficulty.gridSize;
  int get moveLimit => difficulty.moveLimit;

  GameConfig copyWith({GameDifficulty? difficulty}) {
    return GameConfig(difficulty: difficulty ?? this.difficulty);
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'difficulty': difficulty.name,
      'gridSize': gridSize,
      'moveLimit': moveLimit,
    };
  }

  factory GameConfig.fromJson(Map<String, dynamic> json) {
    final String? difficultyName = json['difficulty'] as String?;
    final int? gridSize = (json['gridSize'] as num?)?.toInt();
    final int? moveLimit = (json['moveLimit'] as num?)?.toInt();

    final GameDifficulty difficulty;

    if (difficultyName != null) {
      difficulty = GameDifficulty.fromName(difficultyName);
    } else if (gridSize != null) {
      difficulty = GameDifficulty.fromGridSize(gridSize);
    } else {
      throw const FormatException(
        'GameConfig requires difficulty or gridSize.',
      );
    }

    if (gridSize != null && gridSize != difficulty.gridSize) {
      throw FormatException(
        'Grid size $gridSize does not match ${difficulty.name}.',
      );
    }

    if (moveLimit != null && moveLimit != difficulty.moveLimit) {
      throw FormatException(
        'Move limit $moveLimit does not match ${difficulty.name}.',
      );
    }

    return GameConfig(difficulty: difficulty);
  }

  @override
  bool operator ==(Object other) {
    return other is GameConfig && other.difficulty == difficulty;
  }

  @override
  int get hashCode => difficulty.hashCode;
}
