import 'package:crush_word/src/core/gameplay/services/word_validator.dart';
import 'package:crush_word/src/core/repositories/dictionary_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory dictionary repository for testing.
DictionaryRepository _createRepository(Set<String> words) {
  final String dictionaryContent = words.join('\n');

  return DictionaryRepository(assetLoader: (_) async => dictionaryContent);
}

void main() {
  group('WordValidator', () {
    late DictionaryRepository repository;
    late WordValidator validator;

    setUp(() {
      // Provide a small Turkish word set.
      repository = _createRepository(<String>{
        'arı',
        'bal',
        'çay',
        'göl',
        'şiir',
        'üzüm',
        'soru',
        'kale',
        'test',
      });
      validator = WordValidator(dictionaryRepository: repository);
    });

    test('rejects selections shorter than 3 letters', () async {
      final WordValidationResult result = await validator.validate(<String>[
        'A',
        'B',
      ]);

      expect(result.reason, WordValidationReason.tooShort);
      expect(result.isValid, isFalse);
      expect(result.isRejected, isTrue);
    });

    test('rejects single letter selection', () async {
      final WordValidationResult result = await validator.validate(<String>[
        'X',
      ]);

      expect(result.reason, WordValidationReason.tooShort);
      expect(result.isValid, isFalse);
    });

    test('rejects empty selection', () async {
      final WordValidationResult result = await validator.validate(<String>[]);

      expect(result.reason, WordValidationReason.tooShort);
      expect(result.isValid, isFalse);
    });

    test('returns notInDictionary for unknown 3+ letter word', () async {
      final WordValidationResult result = await validator.validate(<String>[
        'X',
        'Y',
        'Z',
      ]);

      expect(result.reason, WordValidationReason.notInDictionary);
      expect(result.isValid, isFalse);
    });

    test('returns valid for a known dictionary word', () async {
      final WordValidationResult result = await validator.validate(<String>[
        'S',
        'O',
        'R',
        'U',
      ]);

      expect(result.reason, WordValidationReason.valid);
      expect(result.isValid, isTrue);
      expect(result.word, 'soru');
    });

    test('normalizes Turkish uppercase İ to lowercase i', () async {
      // 'ŞİİR' should normalize to 'şiir' which is in the dictionary.
      final WordValidationResult result = await validator.validate(<String>[
        'Ş',
        'İ',
        'İ',
        'R',
      ]);

      expect(result.reason, WordValidationReason.valid);
      expect(result.word, 'şiir');
    });

    test('normalizes Turkish I to ı correctly', () async {
      // 'ARI' with dotless I should normalize to 'arı'.
      final WordValidationResult result = await validator.validate(<String>[
        'A',
        'R',
        'I',
      ]);

      expect(result.reason, WordValidationReason.valid);
      expect(result.word, 'arı');
    });

    test('handles Turkish Ü/Ö/Ç/Ğ correctly', () async {
      final WordValidationResult result = await validator.validate(<String>[
        'Ü',
        'Z',
        'Ü',
        'M',
      ]);

      expect(result.reason, WordValidationReason.valid);
      expect(result.word, 'üzüm');
    });

    test('normalizes Ç in ÇAY', () async {
      final WordValidationResult result = await validator.validate(<String>[
        'Ç',
        'A',
        'Y',
      ]);

      expect(result.reason, WordValidationReason.valid);
      expect(result.word, 'çay');
    });

    test('normalizes Ö in GÖL', () async {
      final WordValidationResult result = await validator.validate(<String>[
        'G',
        'Ö',
        'L',
      ]);

      expect(result.reason, WordValidationReason.valid);
      expect(result.word, 'göl');
    });

    test('word field is populated even for rejected results', () async {
      final WordValidationResult result = await validator.validate(<String>[
        'Q',
        'W',
        'E',
      ]);

      expect(result.word, 'qwe');
      expect(result.isRejected, isTrue);
    });
  });
}
