import 'package:crush_word/src/core/config/game_rules_config.dart';
import 'package:crush_word/src/core/repositories/dictionary_repository.dart';

/// Result of combo detection for a single valid word.
///
/// Contains the main word plus all unique, order-preserving
/// sub-words (subsequences) found within it.
class ComboResult {
  const ComboResult({required this.mainWord, required this.subWords});

  /// The original normalised word that was played.
  final String mainWord;

  /// Unique sub-words found as contiguous subsequences within
  /// [mainWord], excluding the main word itself.
  /// Each sub-word is at least [ComboDetector.minSubWordLength]
  /// characters long.
  final List<String> subWords;

  /// Total combo count — main word counts as 1, plus each sub-word.
  int get comboCount => 1 + subWords.length;

  /// Whether any sub-words were detected beyond the main word.
  bool get hasCombo => subWords.isNotEmpty;
}

/// Detects combo sub-words within a played word.
///
/// A combo sub-word is a contiguous substring of the main word
/// that:
/// - Has at least [minSubWordLength] characters.
/// - Exists in the dictionary.
/// - Is not the main word itself.
/// - Is unique (the same sub-word is only counted once).
/// - Preserves the letter order of the main word.
///
/// Per the rules in `05-puanlama-ozel-gucler-combo.md`:
/// > Alt kelimeler ana kelimenin harf sırasına göre bulunmalıdır.
/// > Aynı alt kelime birden fazla kez sayılmamalıdır.
class ComboDetector {
  const ComboDetector({
    required DictionaryRepository dictionaryRepository,
    this.minSubWordLength = 3,
  }) : _dictionaryRepository = dictionaryRepository;

  final DictionaryRepository _dictionaryRepository;

  /// Minimum character count for a sub-word to qualify.
  final int minSubWordLength;

  /// Detects all combo sub-words within [word].
  ///
  /// [word] should already be normalised (lowercase Turkish).
  /// The scoring engine can then use the returned [ComboResult]
  /// to compute the total combo score.
  Future<ComboResult> detect(String word) async {
    final String normalised = DictionaryRepository.normalizeWord(word);

    if (normalised.length < minSubWordLength) {
      return ComboResult(mainWord: normalised, subWords: const <String>[]);
    }

    // Generate all contiguous substrings of the main word
    // that are at least minSubWordLength characters long and
    // are not the full word itself.
    final Set<String> candidates = <String>{};

    for (int start = 0; start < normalised.length; start++) {
      for (
        int end = start + minSubWordLength;
        end <= normalised.length;
        end++
      ) {
        final String sub = normalised.substring(start, end);

        // Skip the main word itself.
        if (sub == normalised) {
          continue;
        }

        candidates.add(sub);
      }
    }

    if (candidates.isEmpty) {
      return ComboResult(mainWord: normalised, subWords: const <String>[]);
    }

    // Batch-check all candidates against the dictionary.
    final Set<String> validSubWords = await _dictionaryRepository.lookupWords(
      candidates,
    );

    return ComboResult(
      mainWord: normalised,
      subWords: validSubWords.toList(growable: false),
    );
  }
}

/// Combined scoring result including combo information.
///
/// Extends the base word score with combo sub-word scores.
class ComboScoringResult {
  const ComboScoringResult({
    required this.mainWordScore,
    required this.comboResult,
    required this.subWordScores,
    required this.totalScore,
  });

  /// Score from the main word alone.
  final int mainWordScore;

  /// Combo detection result with sub-words.
  final ComboResult comboResult;

  /// Per sub-word score breakdown.
  final Map<String, int> subWordScores;

  /// Total score = main word + all sub-word scores.
  final int totalScore;

  /// Number of combo hits (1 for main + sub-words count).
  int get comboCount => comboResult.comboCount;

  /// Whether any combo was detected.
  bool get hasCombo => comboResult.hasCombo;

  /// Total score earned from sub-words only.
  int get comboBonus => totalScore - mainWordScore;
}

/// Scores a word with full combo support.
///
/// Combines [ScoringConfig] letter scoring with [ComboDetector]
/// sub-word detection. Each valid sub-word's letter scores are
/// summed and added to the total.
class ComboScoringEngine {
  const ComboScoringEngine({required ScoringConfig scoringConfig})
    : _config = scoringConfig;

  final ScoringConfig _config;

  /// Score a [mainWord] and its [comboResult] sub-words.
  ComboScoringResult scoreWithCombo({
    required String mainWord,
    required int mainWordScore,
    required ComboResult comboResult,
  }) {
    final Map<String, int> subWordScores = <String, int>{};
    int comboTotal = mainWordScore;

    for (final String subWord in comboResult.subWords) {
      final String upper = subWord.toUpperCase();
      int subScore = 0;
      for (int i = 0; i < upper.length; i++) {
        subScore += _config.scoreOf(upper[i]);
      }
      subWordScores[subWord] = subScore;
      comboTotal += subScore;
    }

    return ComboScoringResult(
      mainWordScore: mainWordScore,
      comboResult: comboResult,
      subWordScores: subWordScores,
      totalScore: comboTotal,
    );
  }
}
