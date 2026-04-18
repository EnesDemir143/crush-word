import 'package:crush_word/src/core/models/game_config.dart';
import 'package:crush_word/src/core/models/game_difficulty.dart';

class GameRulesConfig {
  const GameRulesConfig({required this.setup});

  final GameSetupRules setup;

  factory GameRulesConfig.fromJson(Map<String, dynamic> json) {
    final Object? setupJson = json['setup'];

    if (setupJson is! Map<String, dynamic>) {
      throw const FormatException(
        'Game rules config requires a valid setup section.',
      );
    }

    return GameRulesConfig(setup: GameSetupRules.fromJson(setupJson));
  }
}

class GameSetupRules {
  const GameSetupRules({
    required this.difficultyOptions,
    required this.moveCountOptions,
  });

  final List<GameSetupOption> difficultyOptions;
  final List<GameMoveCountOption> moveCountOptions;

  factory GameSetupRules.fromJson(Map<String, dynamic> json) {
    final Object? difficultyOptionsJson = json['difficultyOptions'];
    final Object? moveCountOptionsJson = json['moveCountOptions'];

    if (difficultyOptionsJson is! List<dynamic> ||
        difficultyOptionsJson.isEmpty) {
      throw const FormatException(
        'Setup rules require at least one difficulty option.',
      );
    }

    if (moveCountOptionsJson is! List<dynamic> ||
        moveCountOptionsJson.isEmpty) {
      throw const FormatException(
        'Setup rules require at least one move count option.',
      );
    }

    return GameSetupRules(
      difficultyOptions: difficultyOptionsJson
          .map((Object? optionJson) {
            if (optionJson is! Map<String, dynamic>) {
              throw const FormatException(
                'Each difficulty option must be a JSON object.',
              );
            }

            return GameSetupOption.fromJson(optionJson);
          })
          .toList(growable: false),
      moveCountOptions: moveCountOptionsJson
          .map((Object? optionJson) {
            if (optionJson is! Map<String, dynamic>) {
              throw const FormatException(
                'Each move count option must be a JSON object.',
              );
            }

            return GameMoveCountOption.fromJson(optionJson);
          })
          .toList(growable: false),
    );
  }
}

class GameSetupOption {
  const GameSetupOption({
    required this.difficulty,
    required this.label,
    required this.gridLabel,
    required this.gridSize,
  });

  final GameDifficulty difficulty;
  final String label;
  final String gridLabel;
  final int gridSize;

  GameConfig toGameConfig({required int moveLimit}) {
    return GameConfig(
      difficulty: difficulty,
      difficultyLabel: label,
      gridSize: gridSize,
      moveLimit: moveLimit,
    );
  }

  factory GameSetupOption.fromJson(Map<String, dynamic> json) {
    final String difficultyName = (json['difficulty'] as String?)?.trim() ?? '';
    final String label = (json['label'] as String?)?.trim() ?? '';
    final String gridLabel = (json['gridLabel'] as String?)?.trim() ?? '';
    final int? gridSize = (json['gridSize'] as num?)?.toInt();

    if (difficultyName.isEmpty ||
        label.isEmpty ||
        gridLabel.isEmpty ||
        gridSize == null) {
      throw const FormatException(
        'Difficulty option requires difficulty, label, gridLabel and gridSize.',
      );
    }

    return GameSetupOption(
      difficulty: GameDifficulty.fromName(difficultyName),
      label: label,
      gridLabel: gridLabel,
      gridSize: gridSize,
    );
  }
}

class GameMoveCountOption {
  const GameMoveCountOption({
    required this.difficulty,
    required this.label,
    required this.moveLimit,
  });

  final GameDifficulty difficulty;
  final String label;
  final int moveLimit;

  String get ctaLabel => '$label - $moveLimit hamle';

  factory GameMoveCountOption.fromJson(Map<String, dynamic> json) {
    final String difficultyName = (json['difficulty'] as String?)?.trim() ?? '';
    final String label = (json['label'] as String?)?.trim() ?? '';
    final int? moveLimit = (json['moveLimit'] as num?)?.toInt();

    if (difficultyName.isEmpty || label.isEmpty || moveLimit == null) {
      throw const FormatException(
        'Move count option requires difficulty, label and moveLimit.',
      );
    }

    return GameMoveCountOption(
      difficulty: GameDifficulty.fromName(difficultyName),
      label: label,
      moveLimit: moveLimit,
    );
  }
}
