import 'package:flutter_test/flutter_test.dart';

import 'package:crush_word/src/core/config/game_rules_config.dart';
import 'package:crush_word/src/core/gameplay/services/scoring_engine.dart';

/// Canonical letter scores from the PDF-confirmed table.
///
/// This map is the single test-side source of truth and must
/// match `assets/config/game_rules.json` exactly.
const Map<String, int> _canonicalScores = <String, int>{
  'A': 1,
  'B': 3,
  'C': 4,
  'Ç': 4,
  'D': 3,
  'E': 1,
  'F': 7,
  'G': 5,
  'Ğ': 8,
  'H': 5,
  'I': 2,
  'İ': 1,
  'J': 10,
  'K': 1,
  'L': 1,
  'M': 2,
  'N': 1,
  'O': 2,
  'Ö': 7,
  'P': 5,
  'R': 1,
  'S': 2,
  'Ş': 4,
  'T': 1,
  'U': 2,
  'Ü': 3,
  'V': 7,
  'Y': 3,
  'Z': 4,
};

ScoringEngine _engine() =>
    ScoringEngine(scoringConfig: ScoringConfig(letterScores: _canonicalScores));

void main() {
  group('ScoringEngine', () {
    test('scores documented sample word "soru" as 7', () {
      // S=2, O=2, R=1, U=2  → total 7
      final ScoringResult result = _engine().score('soru');

      expect(result.totalScore, 7);
      expect(result.letterScores, <int>[2, 2, 1, 2]);
      expect(result.word, 'SORU');
      expect(result.wordLength, 4);
    });

    test('handles Turkish İ (dotted capital I) correctly', () {
      // İ=1
      final ScoringResult result = _engine().score('İ');
      expect(result.totalScore, 1);
    });

    test('handles Turkish I (dotless I) correctly', () {
      // I=2
      final ScoringResult result = _engine().score('I');
      expect(result.totalScore, 2);
    });

    test('handles Turkish Ğ correctly', () {
      // Ğ=8
      final ScoringResult result = _engine().score('Ğ');
      expect(result.totalScore, 8);
    });

    test('handles Turkish Ş correctly', () {
      // Ş=4
      final ScoringResult result = _engine().score('Ş');
      expect(result.totalScore, 4);
    });

    test('handles Turkish Ö correctly', () {
      // Ö=7
      final ScoringResult result = _engine().score('Ö');
      expect(result.totalScore, 7);
    });

    test('handles Turkish Ü correctly', () {
      // Ü=3
      final ScoringResult result = _engine().score('Ü');
      expect(result.totalScore, 3);
    });

    test('handles Turkish Ç correctly', () {
      // Ç=4
      final ScoringResult result = _engine().score('Ç');
      expect(result.totalScore, 4);
    });

    test('scores highest-value letter J as 10', () {
      final ScoringResult result = _engine().score('J');
      expect(result.totalScore, 10);
    });

    test('scores a longer word correctly', () {
      // K=1, A=1, L=1, E=1, M=2 → total 6
      final ScoringResult result = _engine().score('kalem');
      expect(result.totalScore, 6);
      expect(result.letterScores, <int>[1, 1, 1, 1, 2]);
    });

    test('per-letter breakdown length matches word length', () {
      final ScoringResult result = _engine().score('masa');
      expect(result.letterScores.length, result.wordLength);
    });

    test('returns 0 for unknown characters', () {
      // '?' is not in the table
      final ScoringResult result = _engine().score('?');
      expect(result.totalScore, 0);
    });

    test('case-insensitive: lowercase same as uppercase', () {
      final ScoringEngine engine = _engine();
      final ScoringResult lower = engine.score('soru');
      final ScoringResult upper = engine.score('SORU');

      expect(lower.totalScore, upper.totalScore);
      expect(lower.letterScores, upper.letterScores);
    });

    test('empty string scores 0', () {
      final ScoringResult result = _engine().score('');
      expect(result.totalScore, 0);
      expect(result.letterScores, isEmpty);
    });
  });

  group('ScoringConfig', () {
    test('scoreOf is case-insensitive', () {
      final ScoringConfig config = ScoringConfig(
        letterScores: _canonicalScores,
      );
      expect(config.scoreOf('a'), 1);
      expect(config.scoreOf('A'), 1);
    });

    test('scoreOf returns 0 for unknown letter', () {
      final ScoringConfig config = ScoringConfig(
        letterScores: _canonicalScores,
      );
      expect(config.scoreOf('X'), 0);
    });

    test('fromJson parses correctly', () {
      final ScoringConfig config = ScoringConfig.fromJson(<String, dynamic>{
        'letterScores': <String, dynamic>{'A': 1, 'B': 3},
      });
      expect(config.scoreOf('A'), 1);
      expect(config.scoreOf('B'), 3);
    });

    test('fromJson throws on missing letterScores', () {
      expect(
        () => ScoringConfig.fromJson(<String, dynamic>{}),
        throwsFormatException,
      );
    });
  });
}
