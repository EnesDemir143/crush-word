import 'package:flutter/material.dart';

import 'package:crush_word/src/app/app_routes.dart';
import 'package:crush_word/src/core/models/app_user.dart';
import 'package:crush_word/src/core/repositories/profile_repository.dart';
import 'package:crush_word/src/features/game_setup/game_setup_routes.dart';
import 'package:crush_word/src/features/home/home_screen.dart';
import 'package:crush_word/src/features/market/market_routes.dart';
import 'package:crush_word/src/features/onboarding/username_gate.dart';
import 'package:crush_word/src/features/score_history/score_history_routes.dart';

class AppDestination {
  const AppDestination({
    required this.label,
    required this.routeName,
    required this.icon,
    required this.description,
  });

  final String label;
  final String routeName;
  final IconData icon;
  final String description;
}

class AppRouter {
  AppRouter({required this.profileRepository});

  final ProfileRepository profileRepository;

  static const primaryDestinations = <AppDestination>[
    AppDestination(
      label: 'Yeni Oyun',
      routeName: AppRoutes.newGame,
      icon: Icons.play_circle_fill_rounded,
      description: 'Yeni bir kelime serisi başlat.',
    ),
    AppDestination(
      label: 'Skor Tablosu',
      routeName: AppRoutes.scoreHistory,
      icon: Icons.leaderboard_rounded,
      description: 'Geçmiş sonuçlarını ve zirveyi incele.',
    ),
    AppDestination(
      label: 'Market',
      routeName: AppRoutes.market,
      icon: Icons.local_mall_rounded,
      description: 'Jokerlerini ve altın planını yönet.',
    ),
  ];

  Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name ?? AppRoutes.onboarding) {
      case AppRoutes.onboarding:
        return MaterialPageRoute<void>(
          builder: (_) => UsernameGate(profileRepository: profileRepository),
          settings: settings,
        );
      case AppRoutes.home:
        final AppUser? user = settings.arguments is AppUser
            ? settings.arguments as AppUser
            : null;

        return MaterialPageRoute<void>(
          builder: (_) => user == null
              ? UsernameGate(profileRepository: profileRepository)
              : HomeScreen(
                  initialUser: user,
                  profileRepository: profileRepository,
                ),
          settings: settings,
        );
      case AppRoutes.newGame:
      case AppRoutes.gameSession:
        return GameSetupRoutes.build(settings);
      case AppRoutes.market:
        return MarketRoutes.build(settings);
      case AppRoutes.scoreHistory:
        return ScoreHistoryRoutes.build(settings);
      default:
        return MaterialPageRoute<void>(
          builder: (_) => UsernameGate(profileRepository: profileRepository),
          settings: settings,
        );
    }
  }
}
