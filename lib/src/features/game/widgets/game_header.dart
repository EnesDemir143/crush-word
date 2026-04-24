import 'package:flutter/material.dart';

class GameHeader extends StatelessWidget {
  const GameHeader({
    super.key,
    required this.score,
    required this.movesLeft,
    required this.activeWord,
    required this.compact,
    this.lastWordScore = 0,
    this.comboCount = 1,
    this.playableWordCount = 0,
    this.showActiveWord = true,
  });

  final int score;
  final int movesLeft;
  final String activeWord;
  final bool compact;

  /// Score earned on the last valid word — triggers "+X" animation.
  final int lastWordScore;

  /// Combo count from the last valid word (x1 = no extra combo).
  final int comboCount;

  /// Number of non-overlapping playable words on the current board.
  final int playableWordCount;

  /// Whether the active-word strip is rendered inside this fixed panel.
  final bool showActiveWord;

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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final Widget movesBadge = _PillBadge(
                  icon: Icons.swipe_rounded,
                  label: '$movesLeft hamle',
                  color: movesLeft <= 3
                      ? const Color(0xFFB91C1C)
                      : const Color(0xFF2E8B7A),
                );
                final Widget scorePill = _AnimatedScorePill(
                  score: score,
                  lastWordScore: lastWordScore,
                  comboCount: comboCount,
                );
                final Widget playablePill = _PlayableWordCountPill(
                  count: playableWordCount,
                );

                if (compact || constraints.maxWidth < 360) {
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[movesBadge, scorePill, playablePill],
                  );
                }

                return Row(
                  children: <Widget>[
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: movesBadge,
                      ),
                    ),
                    scorePill,
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: playablePill,
                      ),
                    ),
                  ],
                );
              },
            ),
            // ── Active word strip ────────────────────────
            if (showActiveWord && activeWord.isNotEmpty) ...[
              const SizedBox(height: 8),
              _ActiveWordStrip(word: activeWord),
            ],
          ],
        ),
      ),
    );
  }
}

class _AnimatedScorePill extends StatefulWidget {
  const _AnimatedScorePill({
    required this.score,
    required this.lastWordScore,
    required this.comboCount,
  });

  final int score;
  final int lastWordScore;
  final int comboCount;

  @override
  State<_AnimatedScorePill> createState() => _AnimatedScorePillState();
}

class _AnimatedScorePillState extends State<_AnimatedScorePill>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _pulseController;
  late Animation<Offset> _floatOffset;
  late Animation<double> _floatOpacity;
  late Animation<double> _pulseScale;

  int _displayedDelta = 0;
  int _displayedScore = 0;

  @override
  void initState() {
    super.initState();
    _displayedScore = widget.score;

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _floatOffset = Tween<Offset>(begin: Offset.zero, end: const Offset(0, -1.8))
        .animate(
          CurvedAnimation(parent: _floatController, curve: Curves.easeOutCubic),
        );
    _floatOpacity = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _floatController, curve: const Interval(0.5, 1)),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _pulseScale =
        TweenSequence<double>(<TweenSequenceItem<double>>[
          TweenSequenceItem<double>(
            tween: Tween<double>(begin: 1, end: 1.25),
            weight: 40,
          ),
          TweenSequenceItem<double>(
            tween: Tween<double>(begin: 1.25, end: 1),
            weight: 60,
          ),
        ]).animate(
          CurvedAnimation(parent: _pulseController, curve: Curves.easeOutCubic),
        );
  }

  @override
  void didUpdateWidget(covariant _AnimatedScorePill oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.lastWordScore > 0 &&
        widget.lastWordScore != oldWidget.lastWordScore) {
      _displayedDelta = widget.lastWordScore;
      _floatController
        ..reset()
        ..forward();
      _pulseController
        ..reset()
        ..forward();
    }

    _displayedScore = widget.score;
  }

  @override
  void dispose() {
    _floatController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 62,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: <Widget>[
          // Floating "+X" label
          if (_displayedDelta > 0)
            AnimatedBuilder(
              animation: _floatController,
              builder: (BuildContext context, Widget? child) {
                return Positioned(
                  top: -8 + (_floatOffset.value.dy * 20),
                  child: Opacity(opacity: _floatOpacity.value, child: child),
                );
              },
              child: Text(
                '+$_displayedDelta',
                style: const TextStyle(
                  color: Color(0xFFD4A017),
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          // Score pill with pulse
          AnimatedBuilder(
            animation: _pulseController,
            builder: (BuildContext context, Widget? child) {
              return Transform.scale(scale: _pulseScale.value, child: child);
            },
            child: _DigitalScoreDisplay(
              value: _formatScore(_displayedScore),
              comboCount: widget.comboCount,
            ),
          ),
        ],
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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

String _formatScore(int score) {
  final String raw = score.toString();
  return raw.length >= 4 ? raw : raw.padLeft(4, '0');
}

class _DigitalScoreDisplay extends StatelessWidget {
  const _DigitalScoreDisplay({required this.value, required this.comboCount});

  final String value;
  final int comboCount;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFFFFF7E6), Color(0xFFF3E4BE)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2C98C), width: 1.2),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x1F8B6A12),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 5, 12, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'SKOR',
              style: TextStyle(
                color: const Color(0xFF8B6A12).withValues(alpha: 0.92),
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.6,
                height: 1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              key: const Key('game-score-display'),
              style: const TextStyle(
                color: Color(0xFFD28C00),
                fontSize: 22,
                fontWeight: FontWeight.w900,
                height: 1,
                letterSpacing: 2.8,
                fontFamily: 'monospace',
                fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                shadows: <Shadow>[
                  Shadow(color: Color(0x66FFD54F), blurRadius: 8),
                  Shadow(
                    color: Color(0x33FFF8E1),
                    offset: Offset(0, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'x${comboCount <= 0 ? 1 : comboCount}',
              key: const Key('game-combo-display'),
              style: TextStyle(
                color: comboCount > 1
                    ? const Color(0xFFB77A00)
                    : const Color(0xFF8B6A12).withValues(alpha: 0.7),
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                height: 1,
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF2E8B7A), Color(0xFF1A5D57)],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF1A5D57).withValues(alpha: 0.18),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          children: <Widget>[
            Icon(
              Icons.text_fields_rounded,
              color: Colors.white.withValues(alpha: 0.7),
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

class _PlayableWordCountPill extends StatefulWidget {
  const _PlayableWordCountPill({required this.count});

  final int count;

  @override
  State<_PlayableWordCountPill> createState() => _PlayableWordCountPillState();
}

class _PlayableWordCountPillState extends State<_PlayableWordCountPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseScale;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _pulseScale =
        TweenSequence<double>(<TweenSequenceItem<double>>[
          TweenSequenceItem<double>(
            tween: Tween<double>(begin: 1, end: 1.2),
            weight: 40,
          ),
          TweenSequenceItem<double>(
            tween: Tween<double>(begin: 1.2, end: 1),
            weight: 60,
          ),
        ]).animate(
          CurvedAnimation(parent: _pulseController, curve: Curves.easeOutCubic),
        );
  }

  @override
  void didUpdateWidget(covariant _PlayableWordCountPill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.count != oldWidget.count) {
      _pulseController
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (BuildContext context, Widget? child) {
        return Transform.scale(scale: _pulseScale.value, child: child);
      },
      child: _MetricPill(
        icon: Icons.auto_stories_rounded,
        value: '${widget.count}',
        color: const Color(0xFF7C5CBF),
      ),
    );
  }
}
