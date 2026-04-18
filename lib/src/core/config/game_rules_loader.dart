import 'dart:convert';

import 'package:flutter/services.dart';

import 'package:crush_word/src/core/config/game_rules_config.dart';

class GameRulesLoader {
  const GameRulesLoader({
    AssetBundle? bundle,
    this.assetPath = 'assets/config/game_rules.json',
  }) : _bundle = bundle;

  final AssetBundle? _bundle;
  final String assetPath;

  AssetBundle get _assetBundle => _bundle ?? rootBundle;

  Future<GameRulesConfig> load() async {
    final String rawJson = await _assetBundle.loadString(assetPath);
    final Object? decoded = jsonDecode(rawJson);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Game rules JSON must decode to an object.');
    }

    return GameRulesConfig.fromJson(decoded);
  }
}
