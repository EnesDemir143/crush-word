import 'package:flutter_test/flutter_test.dart';

import 'package:crush_word/src/core/repositories/dictionary_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads the packaged dictionary asset for offline lookup', () async {
    final DictionaryRepository repository = DictionaryRepository();

    expect(await repository.contains('kalem'), isTrue);
    expect(await repository.contains('İSTANBUL'), isTrue);
    expect(await repository.contains('xzyt'), isFalse);
  });

  test('normalizes Turkish casing and punctuation during lookup', () async {
    final DictionaryRepository repository = DictionaryRepository(
      assetLoader: (_) async => 'ışık\nçiçek\nkalem\n',
    );

    expect(await repository.contains(' IŞIK '), isTrue);
    expect(await repository.contains('ÇİÇEK!'), isTrue);
    expect(await repository.contains('Kalem?'), isTrue);
    expect(await repository.contains('ab'), isFalse);
  });

  test('lookupWords returns normalized matches once', () async {
    final DictionaryRepository repository = DictionaryRepository(
      assetLoader: (_) async => 'kalem\nçiçek\nışık\n',
    );

    final Set<String> matches = await repository.lookupWords(<String>[
      'KALEM',
      'çiçek',
      'çiçek!',
      'x',
    ]);

    expect(matches, <String>{'kalem', 'çiçek'});
  });
}
