import 'package:flutter_test/flutter_test.dart';

import 'package:crush_word/src/app/word_crush_app.dart';
import 'package:crush_word/src/core/repositories/profile_repository.dart';
import 'package:crush_word/src/core/storage/local_storage_service.dart';

void main() {
  testWidgets('Word Crush boots without demo branding', (
    WidgetTester tester,
  ) async {
    final ProfileRepository repository = ProfileRepository(
      storage: InMemoryLocalStorageService(),
    );

    await tester.pumpWidget(WordCrushApp(profileRepository: repository));
    await tester.pumpAndSettle();

    expect(find.text('Flutter Demo'), findsNothing);
    expect(find.text('Flutter Demo Home Page'), findsNothing);
    expect(find.text('Word Crush'), findsWidgets);
    expect(find.text('Word Crush\'a hoş geldin'), findsOneWidget);
  });
}

class InMemoryLocalStorageService implements LocalStorageService {
  InMemoryLocalStorageService([Map<String, String>? seedValues])
    : _values = Map<String, String>.from(
        seedValues ?? const <String, String>{},
      );

  final Map<String, String> _values;

  @override
  Future<String?> readString(String key) async => _values[key];

  @override
  Future<void> remove(String key) async {
    _values.remove(key);
  }

  @override
  Future<void> writeString(String key, String value) async {
    _values[key] = value;
  }
}
