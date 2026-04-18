import 'package:flutter/material.dart';

import 'package:crush_word/src/app/app_routes.dart';

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

const List<AppDestination> primaryDestinations = <AppDestination>[
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
