import 'package:flutter/material.dart';

class ScoreHistoryRoutes {
  static Route<dynamic> build(RouteSettings settings) {
    return MaterialPageRoute<void>(
      builder: (_) => const _ScoreHistoryScreenPlaceholder(),
      settings: settings,
    );
  }
}

class _ScoreHistoryScreenPlaceholder extends StatelessWidget {
  const _ScoreHistoryScreenPlaceholder();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Skor Tablosu')),
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
                  'Skor Tablosu',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Skor geçmişi görünümü için navigasyon hedefi hazır durumda.',
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
