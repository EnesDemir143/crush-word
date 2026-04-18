import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:crush_word/src/app/word_crush_app.dart';
import 'package:crush_word/src/core/repositories/profile_repository.dart';
import 'package:crush_word/src/core/storage/local_storage_service.dart';

void main() {
  testWidgets('first launch asks for username and opens the home menu', (
    WidgetTester tester,
  ) async {
    final ProfileRepository repository = ProfileRepository(
      storage: InMemoryLocalStorageService(),
    );

    await tester.pumpWidget(WordCrushApp(profileRepository: repository));
    await tester.pumpAndSettle();

    expect(find.text('Word Crush\'a hoş geldin'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'Enes');
    await tester.tap(find.widgetWithText(FilledButton, 'Başla'));
    await tester.pumpAndSettle();

    expect(find.text('Enes'), findsOneWidget);
    expect(find.text('Yeni Oyun'), findsOneWidget);
    expect(find.text('Skor Tablosu'), findsOneWidget);
    expect(find.text('Market'), findsOneWidget);
  });

  testWidgets('saved username is reused and can be edited from home', (
    WidgetTester tester,
  ) async {
    final InMemoryLocalStorageService storage = InMemoryLocalStorageService({
      'profile.username': 'Enes',
    });
    final ProfileRepository repository = ProfileRepository(storage: storage);

    await tester.pumpWidget(WordCrushApp(profileRepository: repository));
    await tester.pumpAndSettle();

    expect(find.text('Enes'), findsOneWidget);
    expect(find.text('Word Crush\'a hoş geldin'), findsNothing);

    await tester.tap(find.byKey(const Key('home-username-button')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), 'Demir');
    await tester.tap(find.widgetWithText(FilledButton, 'Güncelle'));
    await tester.pumpAndSettle();

    expect(find.text('Demir'), findsOneWidget);
    expect(await storage.readString('profile.username'), 'Demir');
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
