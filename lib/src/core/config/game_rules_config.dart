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
  const GameSetupRules({required this.difficultyOptions});

  final List<GameSetupOption> difficultyOptions;

  factory GameSetupRules.fromJson(Map<String, dynamic> json) {
    final Object? optionsJson = json['difficultyOptions'];

    if (optionsJson is! List<dynamic> || optionsJson.isEmpty) {
      throw const FormatException(
        'Setup rules require at least one difficulty option.',
      );
    }

    return GameSetupRules(
      difficultyOptions: optionsJson
          .map((Object? optionJson) {
            if (optionJson is! Map<String, dynamic>) {
              throw const FormatException(
                'Each difficulty option must be a JSON object.',
              );
            }

            return GameSetupOption.fromJson(optionJson);
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
    required this.moveCountOptions,
  });

  final GameDifficulty difficulty;
  final String label;
  final String gridLabel;
  final int gridSize;
  final List<int> moveCountOptions;

  String get moveSummary {
    if (moveCountOptions.length == 1) {
      return '${moveCountOptions.single} hamle';
    }

    return moveCountOptions.map((int count) => '$count').join(' / ');
  }

  GameConfig toGameConfig({required int moveLimit}) {
    if (!moveCountOptions.contains(moveLimit)) {
      throw ArgumentError.value(
        moveLimit,
        'moveLimit',
        'Move limit is not allowed for ${difficulty.name}.',
      );
    }

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
    final List<int> moveCountOptions =
        ((json['moveCountOptions'] as List?)
                  ?.map((Object? value) => (value as num?)?.toInt())
                  .whereType<int>()
                  .toSet()
                  .toList() ??
              const <int>[])
          ..sort();

    if (difficultyName.isEmpty ||
        label.isEmpty ||
        gridLabel.isEmpty ||
        gridSize == null ||
        moveCountOptions.isEmpty) {
      throw const FormatException(
        'Difficulty option requires difficulty, label, gridLabel, gridSize and moveCountOptions.',
      );
    }

    return GameSetupOption(
      difficulty: GameDifficulty.fromName(difficultyName),
      label: label,
      gridLabel: gridLabel,
      gridSize: gridSize,
      moveCountOptions: List<int>.unmodifiable(moveCountOptions),
    );
  }
}
