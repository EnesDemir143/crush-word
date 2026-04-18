import 'dart:collection';

import 'package:flutter/services.dart';

typedef DictionaryAssetLoader = Future<String> Function(String assetPath);

class DictionaryRepository {
  DictionaryRepository({
    DictionaryAssetLoader? assetLoader,
    this.assetPath = defaultAssetPath,
  }) : _assetLoader =
           assetLoader ?? ((String path) => rootBundle.loadString(path));

  static const String defaultAssetPath = 'assets/dictionary/tr_words.txt';
  static const Map<String, String> _turkishLowercaseMap = <String, String>{
    'I': 'ı',
    'İ': 'i',
    'Ç': 'ç',
    'Ğ': 'ğ',
    'Ö': 'ö',
    'Ş': 'ş',
    'Ü': 'ü',
  };

  final DictionaryAssetLoader _assetLoader;
  final String assetPath;

  Future<Set<String>>? _cachedWords;

  Future<Set<String>> loadWords() {
    return _cachedWords ??= _loadWords();
  }

  Future<bool> contains(String word) async {
    final String normalizedWord = normalizeWord(word);

    if (normalizedWord.length < 3) {
      return false;
    }

    final Set<String> words = await loadWords();
    return words.contains(normalizedWord);
  }

  Future<Set<String>> lookupWords(Iterable<String> words) async {
    final Set<String> dictionaryWords = await loadWords();
    final Set<String> matches = <String>{};

    for (final String word in words) {
      final String normalizedWord = normalizeWord(word);

      if (normalizedWord.length >= 3 &&
          dictionaryWords.contains(normalizedWord)) {
        matches.add(normalizedWord);
      }
    }

    return matches;
  }

  Future<Set<String>> _loadWords() async {
    final String rawDictionary = await _assetLoader(assetPath);
    final Set<String> normalizedWords = <String>{};

    for (final String line in rawDictionary.split(RegExp(r'\r?\n'))) {
      final String normalizedWord = normalizeDictionaryEntry(line);

      if (normalizedWord.length >= 3) {
        normalizedWords.add(normalizedWord);
      }
    }

    return UnmodifiableSetView<String>(normalizedWords);
  }

  static String normalizeWord(String word) {
    final String trimmedWord = word.trim();

    if (trimmedWord.isEmpty) {
      return '';
    }

    final StringBuffer buffer = StringBuffer();

    for (final int rune in trimmedWord.runes) {
      final String character = String.fromCharCode(rune);
      buffer.write(_turkishLowercaseMap[character] ?? character.toLowerCase());
    }

    return buffer.toString().replaceAll(RegExp(r'[^a-zçğıöşü]'), '');
  }

  static String normalizeDictionaryEntry(String entry) {
    final String trimmedEntry = entry.trim();

    if (trimmedEntry.isEmpty || RegExp(r"[\s'’\-]").hasMatch(trimmedEntry)) {
      return '';
    }

    return normalizeWord(trimmedEntry);
  }
}
