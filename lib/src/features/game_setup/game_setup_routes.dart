import 'package:flutter/material.dart';

import 'package:crush_word/src/app/app_routes.dart';
import 'package:crush_word/src/core/models/game_config.dart';
import 'package:crush_word/src/features/game/game_screen.dart';
import 'package:crush_word/src/features/game_setup/new_game_screen.dart';

class GameSetupRoutes {
  static Route<dynamic> build(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.newGame:
        return MaterialPageRoute<void>(
          builder: (BuildContext context) => NewGameScreen(
            onStartGame: (GameConfig config) {
              Navigator.of(
                context,
              ).pushReplacementNamed(AppRoutes.gameSession, arguments: config);
            },
          ),
          settings: settings,
        );
      case AppRoutes.gameSession:
        final GameConfig? config = settings.arguments is GameConfig
            ? settings.arguments as GameConfig
            : null;

        return MaterialPageRoute<void>(
          builder: (_) => config == null
              ? const _InvalidGameSessionScreen()
              : GameScreen(config: config),
          settings: settings,
        );
      default:
        throw ArgumentError.value(
          settings.name,
          'settings.name',
          'Unsupported game setup route.',
        );
    }
  }
}

class _InvalidGameSessionScreen extends StatelessWidget {
  const _InvalidGameSessionScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Oyun Başlatılamadı')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Yeni oyun kurulumu tamamlanmadan oyun oturumu açılamaz.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
