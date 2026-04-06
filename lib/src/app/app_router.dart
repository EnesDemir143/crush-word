import 'package:flutter/material.dart';

import 'package:crush_word/src/core/models/app_user.dart';
import 'package:crush_word/src/core/repositories/profile_repository.dart';
import 'package:crush_word/src/features/home/home_screen.dart';
import 'package:crush_word/src/features/onboarding/username_gate.dart';

class AppRoutes {
  static const onboarding = '/';
  static const home = '/home';
  static const newGame = '/new-game';
  static const market = '/market';
  static const scoreHistory = '/score-history';
}

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
        return _buildPlaceholderRoute(
          settings: settings,
          title: 'Yeni Oyun',
          description:
              'Yeni oyun kurulum akışı bir sonraki fazda bu hedefe bağlanacak.',
        );
      case AppRoutes.market:
        return _buildPlaceholderRoute(
          settings: settings,
          title: 'Market',
          description:
              'Market ekranı için temel hedef hazır; içerik sonraki fazlarda dolacak.',
        );
      case AppRoutes.scoreHistory:
        return _buildPlaceholderRoute(
          settings: settings,
          title: 'Skor Tablosu',
          description:
              'Skor geçmişi görünümü için navigasyon hedefi hazır durumda.',
        );
      default:
        return MaterialPageRoute<void>(
          builder: (_) => UsernameGate(profileRepository: profileRepository),
          settings: settings,
        );
    }
  }

  MaterialPageRoute<void> _buildPlaceholderRoute({
    required RouteSettings settings,
    required String title,
    required String description,
  }) {
    return MaterialPageRoute<void>(
      builder: (_) =>
          _PlaceholderScreen(title: title, description: description),
      settings: settings,
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.construction_rounded,
                  size: 52,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  description,
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
