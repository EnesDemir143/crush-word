import 'package:crush_word/src/core/config/game_rules_config.dart';
import 'package:crush_word/src/core/gameplay/services/combo_engine.dart';
import 'package:crush_word/src/core/repositories/dictionary_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fake dictionary repository that returns a fixed word set.
///
/// Allows tests to control exactly which substrings are "valid"
/// without touching the real asset bundle.
class _FakeDictionaryRepository extends DictionaryRepository {
  _FakeDictionaryRepository(this._words)
    : super(
        assetLoader: (_) async => '',
        assetPath: 'fake',
      );

  final Set<String> _words;

  @override
  Future<Set<String>> loadWords() async => _words;

  @override
  Future<bool> contains(String word) async {
    final String normalised =
        DictionaryRepository.normalizeWord(word);
    return normalised.length >= 3 && _words.contains(normalised);
  }

  @override
  Future<Set<String>> lookupWords(Iterable<String> words) async {
    final Set<String> matches = <String>{};
    for (final String word in words) {
      final String normalised =
          DictionaryRepository.normalizeWord(word);
      if (normalised.length >= 3 && _words.contains(normalised)) {
        matches.add(normalised);
      }
    }
    return matches;
  }
}

/// Canonical letter-score table matching `game_rules.json`.
ScoringConfig _testScoringConfig() {
  return ScoringConfig(
    letterScores: <String, int>{
      'A': 1, 'B': 3, 'C': 4, 'Ç': 4, 'D': 3,
      'E': 1, 'F': 7, 'G': 5, 'Ğ': 8, 'H': 5,
      'I': 2, 'İ': 1, 'J': 10, 'K': 1, 'L': 1,
      'M': 2, 'N': 1, 'O': 2, 'Ö': 7, 'P': 5,
      'R': 1, 'S': 2, 'Ş': 4, 'T': 1, 'U': 2,
      'Ü': 3, 'V': 7, 'Y': 3, 'Z': 4,
    },
  );
}

void main() {
  // ───────────────────────────────────────────────────────
  // ComboDetector tests
  // ───────────────────────────────────────────────────────

  group('ComboDetector', () {
    test('ADANA → detects contiguous subwords (ada, ana)', () async {
      // "adana" has contiguous substrings: ada, dan, ana, adan, dana
      // We mark only "ada" and "ana" as dictionary words.
      final _FakeDictionaryRepository repo = _FakeDictionaryRepository(
        <String>{'ada', 'ana', 'adana'},
      );
      final ComboDetector detector = ComboDetector(
        dictionaryRepository: repo,
      );

      final ComboResult result = await detector.detect('ADANA');

      expect(result.mainWord, 'adana');
      expect(result.subWords, unorderedEquals(<String>['ada', 'ana']));
      expect(result.hasCombo, isTrue);
      // Main (1) + 2 sub-words = 3
      expect(result.comboCount, 3);
    });

    test('MASAL → detects masa, asal as valid subwords', () async {
      final _FakeDictionaryRepository repo = _FakeDictionaryRepository(
        <String>{'masal', 'masa', 'asal', 'sal'},
      );
      final ComboDetector detector = ComboDetector(
        dictionaryRepository: repo,
      );

      final ComboResult result = await detector.detect('MASAL');

      expect(result.mainWord, 'masal');
      expect(
        result.subWords,
        unorderedEquals(<String>['masa', 'asal', 'sal']),
      );
      expect(result.comboCount, 4);
    });

    test('SARI → detects valid contiguous subwords', () async {
      // "SARI" normalises to "sarı" (Turkish I→ı).
      // Contiguous substrings ≥3 (excluding main): sar, arı
      final _FakeDictionaryRepository repo = _FakeDictionaryRepository(
        <String>{'sarı', 'arı', 'sar'},
      );
      final ComboDetector detector = ComboDetector(
        dictionaryRepository: repo,
      );

      final ComboResult result = await detector.detect('SARI');

      expect(result.mainWord, 'sarı');
      // Both "sar" and "arı" are valid dictionary substrings.
      expect(
        result.subWords,
        unorderedEquals(<String>['arı', 'sar']),
      );
      expect(result.comboCount, 3);
    });

    test('duplicate subwords are counted once', () async {
      // "abcabc" has "abc" appearing twice as a substring.
      // Dictionary marks "abc" as valid.
      final _FakeDictionaryRepository repo = _FakeDictionaryRepository(
        <String>{'abc', 'abcabc'},
      );
      final ComboDetector detector = ComboDetector(
        dictionaryRepository: repo,
      );

      final ComboResult result = await detector.detect('ABCABC');

      // "abc" should appear only once despite occurring at
      // positions 0-3 and 3-6.
      final int abcOccurrences =
          result.subWords.where((String w) => w == 'abc').length;
      expect(abcOccurrences, 1);
    });

    test('word shorter than minSubWordLength returns no combo',
        () async {
      final _FakeDictionaryRepository repo = _FakeDictionaryRepository(
        <String>{'ab'},
      );
      final ComboDetector detector = ComboDetector(
        dictionaryRepository: repo,
      );

      final ComboResult result = await detector.detect('AB');

      expect(result.subWords, isEmpty);
      expect(result.hasCombo, isFalse);
      expect(result.comboCount, 1);
    });

    test('three-letter word with no valid sub-words returns '
        'no combo', () async {
      // "xyz" has no contiguous substrings ≥ 3 that differ
      // from the main word.
      final _FakeDictionaryRepository repo = _FakeDictionaryRepository(
        <String>{'xyz'},
      );
      final ComboDetector detector = ComboDetector(
        dictionaryRepository: repo,
      );

      final ComboResult result = await detector.detect('XYZ');

      expect(result.subWords, isEmpty);
      expect(result.hasCombo, isFalse);
    });

    test('main word is excluded from subword list', () async {
      final _FakeDictionaryRepository repo = _FakeDictionaryRepository(
        <String>{'test', 'tes', 'est'},
      );
      final ComboDetector detector = ComboDetector(
        dictionaryRepository: repo,
      );

      final ComboResult result = await detector.detect('TEST');

      expect(result.subWords, isNot(contains('test')));
      expect(
        result.subWords,
        unorderedEquals(<String>['tes', 'est']),
      );
    });
  });

  // ───────────────────────────────────────────────────────
  // ComboScoringEngine tests
  // ───────────────────────────────────────────────────────

  group('ComboScoringEngine', () {
    late ComboScoringEngine engine;

    setUp(() {
      engine = ComboScoringEngine(
        scoringConfig: _testScoringConfig(),
      );
    });

    test('reuses canonical letter-score table for sub-words',
        () {
      // "ADA" → A(1) + D(3) + A(1) = 5
      // "ANA" → A(1) + N(1) + A(1) = 3
      // Main "ADANA" → A(1)+D(3)+A(1)+N(1)+A(1) = 7
      final ComboResult combo = ComboResult(
        mainWord: 'adana',
        subWords: <String>['ada', 'ana'],
      );

      final ComboScoringResult result = engine.scoreWithCombo(
        mainWord: 'ADANA',
        mainWordScore: 7,
        comboResult: combo,
      );

      expect(result.mainWordScore, 7);
      expect(result.subWordScores['ada'], 5); // A+D+A
      expect(result.subWordScores['ana'], 3); // A+N+A
      expect(result.totalScore, 7 + 5 + 3); // 15
      expect(result.comboBonus, 8);
      expect(result.comboCount, 3);
    });

    test('no combo subwords returns main score only', () {
      final ComboResult combo = ComboResult(
        mainWord: 'test',
        subWords: const <String>[],
      );

      final ComboScoringResult result = engine.scoreWithCombo(
        mainWord: 'TEST',
        mainWordScore: 10,
        comboResult: combo,
      );

      expect(result.totalScore, 10);
      expect(result.comboBonus, 0);
      expect(result.hasCombo, isFalse);
    });

    test('MASAL total reflects main plus all sub-word scores',
        () {
      // Main "MASAL" → M(2)+A(1)+S(2)+A(1)+L(1) = 7
      // "MASA" → M(2)+A(1)+S(2)+A(1) = 6
      // "ASAL" → A(1)+S(2)+A(1)+L(1) = 5
      // "SAL"  → S(2)+A(1)+L(1) = 4
      final ComboResult combo = ComboResult(
        mainWord: 'masal',
        subWords: <String>['masa', 'asal', 'sal'],
      );

      final ComboScoringResult result = engine.scoreWithCombo(
        mainWord: 'MASAL',
        mainWordScore: 7,
        comboResult: combo,
      );

      expect(result.totalScore, 7 + 6 + 5 + 4); // 22
      expect(result.comboBonus, 15);
      expect(result.comboCount, 4);
    });
  });
}
