import 'package:crush_word/src/core/models/game_config.dart';
import 'package:crush_word/src/core/models/game_difficulty.dart';

/// Canonical letter-score mapping loaded from `game_rules.json`.
///
/// Keys are uppercase Turkish letters.  The map is unmodifiable at
/// construction time so the table cannot drift at runtime.
class ScoringConfig {
  ScoringConfig({required Map<String, int> letterScores})
    : letterScores = Map<String, int>.unmodifiable(letterScores);

  /// Uppercase letter → point value.
  final Map<String, int> letterScores;

  /// Returns the point value for [letter].
  ///
  /// Falls back to 0 when the letter is not in the table
  /// (e.g. a wildcard tile in later phases).
  int scoreOf(String letter) => letterScores[letter.toUpperCase()] ?? 0;

  factory ScoringConfig.fromJson(Map<String, dynamic> json) {
    final Object? scoresJson = json['letterScores'];

    if (scoresJson is! Map<String, dynamic>) {
      throw const FormatException(
        'Scoring config requires a letterScores map.',
      );
    }

    final Map<String, int> parsed = <String, int>{};
    for (final MapEntry<String, dynamic> entry in scoresJson.entries) {
      final int? value = (entry.value as num?)?.toInt();
      if (value == null) {
        throw FormatException(
          'Letter score for "${entry.key}" must be an integer.',
        );
      }
      parsed[entry.key.toUpperCase()] = value;
    }

    return ScoringConfig(letterScores: parsed);
  }
}

class GameRulesConfig {
  const GameRulesConfig({
    required this.setup,
    required this.boardGeneration,
    this.scoring,
    this.market,
  });

  final GameSetupRules setup;
  final GameBoardGenerationRules boardGeneration;

  /// Null when loaded from legacy JSON that predates the scoring
  /// section — callers must handle this gracefully.
  final ScoringConfig? scoring;
  final MarketRules? market;

  factory GameRulesConfig.fromJson(Map<String, dynamic> json) {
    final Object? setupJson = json['setup'];
    final Object? boardGenerationJson = json['boardGeneration'];
    final Object? scoringJson = json['scoring'];
    final Object? marketJson = json['market'];

    if (setupJson is! Map<String, dynamic>) {
      throw const FormatException(
        'Game rules config requires a valid setup section.',
      );
    }

    if (boardGenerationJson is! Map<String, dynamic>) {
      throw const FormatException(
        'Game rules config requires a valid boardGeneration section.',
      );
    }

    return GameRulesConfig(
      setup: GameSetupRules.fromJson(setupJson),
      boardGeneration: GameBoardGenerationRules.fromJson(boardGenerationJson),
      scoring: scoringJson is Map<String, dynamic>
          ? ScoringConfig.fromJson(scoringJson)
          : null,
      market: marketJson is Map<String, dynamic>
          ? MarketRules.fromJson(marketJson)
          : null,
    );
  }
}

class MarketRules {
  const MarketRules({required this.initialGold, required this.jokers});

  final int initialGold;
  final List<MarketJokerDefinition> jokers;

  factory MarketRules.fromJson(Map<String, dynamic> json) {
    final int? initialGold = (json['initialGold'] as num?)?.toInt();
    final Object? jokersJson = json['jokers'];

    if (initialGold == null || initialGold < 0) {
      throw const FormatException(
        'Market rules require a non-negative initialGold value.',
      );
    }

    if (jokersJson is! List<dynamic> || jokersJson.isEmpty) {
      throw const FormatException(
        'Market rules require at least one joker definition.',
      );
    }

    return MarketRules(
      initialGold: initialGold,
      jokers: jokersJson.map((Object? jokerJson) {
        if (jokerJson is! Map<String, dynamic>) {
          throw const FormatException(
            'Each joker definition must be a JSON object.',
          );
        }

        return MarketJokerDefinition.fromJson(jokerJson);
      }).toList(growable: false),
    );
  }
}

class MarketJokerDefinition {
  const MarketJokerDefinition({
    required this.id,
    required this.name,
    required this.cost,
    required this.description,
    required this.purpose,
    required this.usage,
  });

  final String id;
  final String name;
  final int cost;
  final String description;
  final String purpose;
  final String usage;

  factory MarketJokerDefinition.fromJson(Map<String, dynamic> json) {
    final String id = (json['id'] as String?)?.trim() ?? '';
    final String name = (json['name'] as String?)?.trim() ?? '';
    final int? cost = (json['cost'] as num?)?.toInt();
    final String description = (json['description'] as String?)?.trim() ?? '';
    final String purpose = (json['purpose'] as String?)?.trim() ?? '';
    final String usage = (json['usage'] as String?)?.trim() ?? '';

    if (id.isEmpty ||
        name.isEmpty ||
        cost == null ||
        cost < 0 ||
        description.isEmpty ||
        purpose.isEmpty ||
        usage.isEmpty) {
      throw const FormatException(
        'Each joker definition requires id, name, cost and display text.',
      );
    }

    return MarketJokerDefinition(
      id: id,
      name: name,
      cost: cost,
      description: description,
      purpose: purpose,
      usage: usage,
    );
  }
}

class GameBoardGenerationRules {
  const GameBoardGenerationRules({required this.letterFrequencyGroups});

  final List<LetterFrequencyGroup> letterFrequencyGroups;

  int get totalWeight => letterFrequencyGroups.fold<int>(
    0,
    (int total, LetterFrequencyGroup group) => total + group.weight,
  );

  factory GameBoardGenerationRules.fromJson(Map<String, dynamic> json) {
    final Object? frequencyGroupsJson = json['letterFrequencyGroups'];

    if (frequencyGroupsJson is! List<dynamic> || frequencyGroupsJson.isEmpty) {
      throw const FormatException(
        'Board generation rules require at least one letter frequency group.',
      );
    }

    final List<LetterFrequencyGroup> groups = frequencyGroupsJson
        .map((Object? groupJson) {
          if (groupJson is! Map<String, dynamic>) {
            throw const FormatException(
              'Each letter frequency group must be a JSON object.',
            );
          }

          return LetterFrequencyGroup.fromJson(groupJson);
        })
        .toList(growable: false);

    if (groups.fold<int>(
          0,
          (int total, LetterFrequencyGroup group) => total + group.weight,
        ) <=
        0) {
      throw const FormatException(
        'Board generation rules require a positive total weight.',
      );
    }

    return GameBoardGenerationRules(letterFrequencyGroups: groups);
  }
}

enum LetterFrequencyTier {
  high,
  medium,
  low;

  static LetterFrequencyTier fromName(String value) {
    return values.firstWhere(
      (LetterFrequencyTier tier) => tier.name == value,
      orElse: () {
        throw ArgumentError.value(
          value,
          'value',
          'Unknown letter frequency tier.',
        );
      },
    );
  }
}

class LetterFrequencyGroup {
  const LetterFrequencyGroup({
    required this.tier,
    required this.weight,
    required this.letters,
  });

  final LetterFrequencyTier tier;
  final int weight;
  final List<String> letters;

  factory LetterFrequencyGroup.fromJson(Map<String, dynamic> json) {
    final String tierName = (json['tier'] as String?)?.trim() ?? '';
    final int? weight = (json['weight'] as num?)?.toInt();
    final Object? lettersJson = json['letters'];

    if (tierName.isEmpty || weight == null || weight <= 0) {
      throw const FormatException(
        'Letter frequency group requires tier and a positive weight.',
      );
    }

    if (lettersJson is! List<dynamic> || lettersJson.isEmpty) {
      throw const FormatException(
        'Letter frequency group requires at least one letter.',
      );
    }

    final List<String> letters = lettersJson
        .map((Object? letterJson) => (letterJson as String?)?.trim() ?? '')
        .where((String letter) => letter.isNotEmpty)
        .toList(growable: false);

    if (letters.isEmpty) {
      throw const FormatException(
        'Letter frequency group requires non-empty letters.',
      );
    }

    return LetterFrequencyGroup(
      tier: LetterFrequencyTier.fromName(tierName),
      weight: weight,
      letters: letters,
    );
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
