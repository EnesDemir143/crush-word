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

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xDDFFFFFF), Color(0xFFF6EFE2)],
        ),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.10),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF102A24).withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // ── Top row: difficulty + score + moves ──────
            Wrap(
              spacing: 6,
              runSpacing: 6,
              alignment: WrapAlignment.spaceBetween,
              children: <Widget>[
                _PillBadge(
                  icon: Icons.tune_rounded,
                  label: config.difficultyLabel,
                  color: theme.colorScheme.primary,
                ),
                _PillBadge(
                  icon: Icons.grid_4x4_rounded,
                  label: '${config.gridSize}×${config.gridSize}',
                  color: theme.colorScheme.primary,
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _MetricPill(
                      icon: Icons.star_rounded,
                      value: '$score',
                      color: const Color(0xFFD4A017),
                    ),
                    const SizedBox(width: 8),
                    _MetricPill(
                      icon: Icons.swipe_rounded,
                      value: '$movesLeft',
                      color: const Color(0xFF2E8B7A),
                    ),
                  ],
                ),
              ],
            ),
            // ── Active word strip ────────────────────────
            if (activeWord.isNotEmpty) ...[
              const SizedBox(height: 8),
              _ActiveWordStrip(word: activeWord),
            ],
          ],
        ),
      ),
    );
  }
}

class _PillBadge extends StatelessWidget {
  const _PillBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 5,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.icon,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 6,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 5),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveWordStrip extends StatelessWidget {
  const _ActiveWordStrip({required this.word});

  final String word;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF183C38),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 8,
        ),
        child: Row(
          children: <Widget>[
            const Icon(
              Icons.text_fields_rounded,
              color: Color(0xAAFFFFFF),
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                word,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
