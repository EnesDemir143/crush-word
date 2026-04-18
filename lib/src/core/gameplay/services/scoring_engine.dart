import 'package:crush_word/src/core/config/game_rules_config.dart';

/// Per-word scoring result returned by [ScoringEngine].
///
/// Carries the raw score plus metadata that downstream
/// screens (history, end-of-game summary) will consume.
class ScoringResult {
  const ScoringResult({
    required this.word,
    required this.letterScores,
    required this.totalScore,
  });

  /// The normalised word that was scored.
  final String word;

  /// Per-letter breakdown — one entry per character position.
  final List<int> letterScores;

  /// Sum of [letterScores].
  final int totalScore;

  /// Number of letters in the scored word.
  int get wordLength => word.length;
}

/// Pure service that calculates the score for a valid word.
///
/// The engine reads from the canonical [ScoringConfig] loaded at
/// init time.  It never mutates board or session state — the
/// caller owns side-effects.
class ScoringEngine {
  const ScoringEngine({required ScoringConfig scoringConfig})
      : _config = scoringConfig;

  final ScoringConfig _config;

  /// Score [word] using the canonical letter-score table.
  ///
  /// Each character is looked up individually in uppercase form.
  /// Unknown characters (e.g. future wildcards) score 0.
  ScoringResult score(String word) {
    final String upper = word.toUpperCase();

    final List<int> perLetter = List<int>.generate(
      upper.length,
      (int i) => _config.scoreOf(upper[i]),
      growable: false,
    );

    return ScoringResult(
      word: upper,
      letterScores: perLetter,
      totalScore: perLetter.fold<int>(
        0,
        (int sum, int v) => sum + v,
      ),
    );
  }
}
