import 'package:crush_word/src/core/repositories/dictionary_repository.dart';

/// Result reasons for a word validation attempt.
enum WordValidationReason {
  /// Selected path has fewer than 3 letters.
  tooShort,

  /// Word is long enough but not present in the dictionary.
  notInDictionary,

  /// Word is valid — found in the dictionary.
  valid,
}

/// Immutable result of a single word validation attempt.
class WordValidationResult {
  const WordValidationResult({required this.reason, required this.word});

  final WordValidationReason reason;

  /// The normalised word that was tested.
  final String word;

  bool get isValid => reason == WordValidationReason.valid;
  bool get isRejected => !isValid;
}

/// Pure service that validates a word candidate built from a selection path.
///
/// The validator builds the word from the selected letters, normalises
/// Turkish casing through [DictionaryRepository.normalizeWord] and checks
/// the packaged dictionary.  It never mutates board state — the caller
/// owns the side-effects.
class WordValidator {
  const WordValidator({required DictionaryRepository dictionaryRepository})
    : _dictionaryRepository = dictionaryRepository;

  final DictionaryRepository _dictionaryRepository;

  static const int minWordLength = 3;

  /// Validate [letters] as a word candidate.
  ///
  /// Normalises Turkish casing, rejects words shorter than [minWordLength],
  /// and checks the dictionary for existence.
  Future<WordValidationResult> validate(List<String> letters) async {
    final String rawWord = letters.join();
    final String normalised = DictionaryRepository.normalizeWord(rawWord);

    if (normalised.length < minWordLength) {
      return WordValidationResult(
        reason: WordValidationReason.tooShort,
        word: normalised,
      );
    }

    final bool exists = await _dictionaryRepository.contains(normalised);

    return WordValidationResult(
      reason: exists
          ? WordValidationReason.valid
          : WordValidationReason.notInDictionary,
      word: normalised,
    );
  }
}
