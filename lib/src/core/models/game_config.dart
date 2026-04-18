import 'package:crush_word/src/core/models/game_difficulty.dart';

class GameConfig {
  const GameConfig({
    required this.difficulty,
    required this.difficultyLabel,
    required this.gridSize,
    required this.moveLimit,
  });

  final GameDifficulty difficulty;
  final String difficultyLabel;
  final int gridSize;
  final int moveLimit;

  String get gridLabel => '${gridSize}x$gridSize';

  GameConfig copyWith({
    GameDifficulty? difficulty,
    String? difficultyLabel,
    int? gridSize,
    int? moveLimit,
  }) {
    return GameConfig(
      difficulty: difficulty ?? this.difficulty,
      difficultyLabel: difficultyLabel ?? this.difficultyLabel,
      gridSize: gridSize ?? this.gridSize,
      moveLimit: moveLimit ?? this.moveLimit,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'difficulty': difficulty.name,
      'difficultyLabel': difficultyLabel,
      'gridSize': gridSize,
      'moveLimit': moveLimit,
    };
  }

  factory GameConfig.fromJson(Map<String, dynamic> json) {
    final String? difficultyName = json['difficulty'] as String?;
    final String? difficultyLabel = json['difficultyLabel'] as String?;
    final int? gridSize = (json['gridSize'] as num?)?.toInt();
    final int? moveLimit = (json['moveLimit'] as num?)?.toInt();

    if (difficultyName == null ||
        difficultyLabel == null ||
        gridSize == null ||
        moveLimit == null) {
      throw const FormatException(
        'GameConfig requires difficulty, difficultyLabel, gridSize and moveLimit.',
      );
    }

    return GameConfig(
      difficulty: GameDifficulty.fromName(difficultyName),
      difficultyLabel: difficultyLabel,
      gridSize: gridSize,
      moveLimit: moveLimit,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is GameConfig &&
        other.difficulty == difficulty &&
        other.difficultyLabel == difficultyLabel &&
        other.gridSize == gridSize &&
        other.moveLimit == moveLimit;
  }

  @override
  int get hashCode =>
      Object.hash(difficulty, difficultyLabel, gridSize, moveLimit);
}
