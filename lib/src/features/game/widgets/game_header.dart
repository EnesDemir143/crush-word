import 'package:flutter/material.dart';

import 'package:crush_word/src/core/models/game_config.dart';

class GameHeader extends StatelessWidget {
  const GameHeader({
    super.key,
    required this.config,
    required this.score,
    required this.movesLeft,
    required this.activeWord,
    required this.compact,
  });

  final GameConfig config;
  final int score;
  final int movesLeft;
  final String activeWord;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String activeWordValue = activeWord.isEmpty
        ? 'İz sürmeye başla'
        : activeWord;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xCCFFFFFF), Color(0xFFF6EFE2)],
        ),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.14),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF102A24).withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 16 : 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                _HeaderBadge(
                  icon: Icons.tune_rounded,
                  label: config.difficultyLabel,
                ),
                _HeaderBadge(
                  icon: Icons.grid_4x4_rounded,
                  label: config.gridLabel,
                ),
              ],
            ),
            SizedBox(height: compact ? 12 : 14),
            Text(
              compact
                  ? 'Kelime zincirini kur'
                  : 'Tahta hazır, şimdi komşu harflerden iz çıkar',
              style:
                  (compact
                          ? theme.textTheme.titleLarge
                          : theme.textTheme.headlineSmall)
                      ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Text(
              compact
                  ? 'Sürükle, yolu büyüt ve ritmi yakala.'
                  : 'Her sürüklemede yalnızca geçerli komşu yolu uzat. '
                        'Yoğun boardlarda okunabilirlik korunacak şekilde '
                        'ölçeklenen bir oyun yüzeyi kullanılıyor.',
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
            ),
            SizedBox(height: compact ? 14 : 18),
            _ActiveWordPanel(
              value: activeWordValue,
              isPlaceholder: activeWord.isEmpty,
            ),
            SizedBox(height: compact ? 14 : 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                _MetricCard(
                  title: 'Skor',
                  value: '$score',
                  semanticLabel: 'Skor $score',
                  compact: compact,
                ),
                _MetricCard(
                  title: 'Hamle',
                  value: '$movesLeft',
                  semanticLabel: '$movesLeft hamle kaldı',
                  compact: compact,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderBadge extends StatelessWidget {
  const _HeaderBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveWordPanel extends StatelessWidget {
  const _ActiveWordPanel({required this.value, required this.isPlaceholder});

  final String value;
  final bool isPlaceholder;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Semantics(
      container: true,
      label: isPlaceholder ? 'Aktif kelime seçilmedi' : 'Aktif kelime $value',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF183C38),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Aktif Kelime',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.78),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    (isPlaceholder
                            ? theme.textTheme.titleMedium
                            : theme.textTheme.headlineSmall)
                        ?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.semanticLabel,
    required this.compact,
  });

  final String title;
  final String value;
  final String semanticLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Semantics(
      container: true,
      label: semanticLabel,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: compact ? 116 : 132),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.84),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 14 : 16,
              vertical: compact ? 12 : 14,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style:
                      (compact
                              ? theme.textTheme.titleLarge
                              : theme.textTheme.headlineSmall)
                          ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
