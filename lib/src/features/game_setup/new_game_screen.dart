import 'dart:async';

import 'package:flutter/material.dart';

import 'package:crush_word/src/core/config/game_rules_config.dart';
import 'package:crush_word/src/core/models/game_config.dart';
import 'package:crush_word/src/features/game_setup/game_setup_controller.dart';

class NewGameScreen extends StatefulWidget {
  const NewGameScreen({super.key, this.controller, this.onStartGame});

  final GameSetupController? controller;
  final ValueChanged<GameConfig>? onStartGame;

  @override
  State<NewGameScreen> createState() => _NewGameScreenState();
}

class _NewGameScreenState extends State<NewGameScreen> {
  late final GameSetupController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? GameSetupController();
    _ownsController = widget.controller == null;
    unawaited(_controller.load());
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }

    super.dispose();
  }

  Future<bool> _handleBackNavigation() async {
    if (_controller.canStepBack) {
      _controller.returnToDifficultySelection();
      return false;
    }

    return true;
  }

  void _startGame(GameConfig config) {
    final ValueChanged<GameConfig>? onStartGame = widget.onStartGame;

    if (onStartGame != null) {
      onStartGame(config);
      return;
    }

    Navigator.of(context).pop(config);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, _) {
        return PopScope<void>(
          canPop: !_controller.canStepBack,
          onPopInvokedWithResult: (bool didPop, void _) {
            if (!didPop) {
              unawaited(_handleBackNavigation());
            }
          },
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              foregroundColor: const Color(0xFF3A3025),
              elevation: 0,
              scrolledUnderElevation: 0,
              title: Text(
                _controller.step == GameSetupStep.difficulty
                    ? 'Yeni Oyun'
                    : 'Hamle Sayısı',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF3A3025),
                ),
              ),
              leading: _controller.canStepBack
                  ? IconButton(
                      onPressed: _controller.returnToDifficultySelection,
                      icon: const Icon(Icons.arrow_back_rounded),
                    )
                  : null,
            ),
            extendBodyBehindAppBar: true,
            body: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    Color(0xFFFDF8F0),
                    Color(0xFFF5EBDA),
                    Color(0xFFEDE0CB),
                  ],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    24,
                    kToolbarHeight + 20,
                    24,
                    24,
                  ),
                  child: _buildBody(context),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_controller.isLoading && _controller.rules == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_controller.error != null && _controller.rules == null) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Oyun kuralları yüklenemedi.',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Yeni oyun ayarlarını açmak için gerekli config okunamadı.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => _controller.load(force: true),
                child: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      );
    }

    if (_controller.step == GameSetupStep.moveCount) {
      final GameSetupOption option = _controller.selectedDifficulty!;
      return _MoveCountStep(
        option: option,
        moveCountOptions: _controller.availableMoveCountOptions,
        onMoveSelected: (GameMoveCountOption moveCountOption) {
          _startGame(_controller.confirmMoveCount(moveCountOption));
        },
      );
    }

    return _DifficultyStep(
      options: _controller.difficultyOptions,
      onOptionSelected: _controller.selectDifficulty,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Difficulty step
// ─────────────────────────────────────────────────────────────

class _DifficultyStep extends StatelessWidget {
  const _DifficultyStep({
    required this.options,
    required this.onOptionSelected,
  });

  final List<GameSetupOption> options;
  final ValueChanged<GameSetupOption> onOptionSelected;

  static const Map<String, List<Color>> _gradients = <String, List<Color>>{
    'easy': <Color>[Color(0xFF2E8B7A), Color(0xFF3FAF9A)],
    'medium': <Color>[Color(0xFFD4A017), Color(0xFFE6B533)],
    'hard': <Color>[Color(0xFFB03A3A), Color(0xFFD04545)],
  };

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return ListView(
      children: [
        Text(
          'Grid boyutunu seç',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF3A3025),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '6×6 Zor • 8×8 Orta • 10×10 Kolay',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF7A6F62),
          ),
        ),
        const SizedBox(height: 24),
        for (final GameSetupOption option in options) ...[
          _DifficultyCard(
            key: Key('setup-difficulty-${option.difficulty.name}'),
            option: option,
            gradientColors:
                _gradients[option.difficulty.name] ??
                const <Color>[Color(0xFF2E8B7A), Color(0xFF3FAF9A)],
            onTap: () => onOptionSelected(option),
          ),
          const SizedBox(height: 14),
        ],
      ],
    );
  }
}

class _DifficultyCard extends StatefulWidget {
  const _DifficultyCard({
    super.key,
    required this.option,
    required this.gradientColors,
    required this.onTap,
  });

  final GameSetupOption option;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  @override
  State<_DifficultyCard> createState() => _DifficultyCardState();
}

class _DifficultyCardState extends State<_DifficultyCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.gradientColors,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: widget.gradientColors.first.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: <Widget>[
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      Icons.grid_4x4_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        widget.option.gridLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.option.label,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Move count step
// ─────────────────────────────────────────────────────────────

class _MoveCountStep extends StatelessWidget {
  const _MoveCountStep({
    required this.option,
    required this.moveCountOptions,
    required this.onMoveSelected,
  });

  final GameSetupOption option;
  final List<GameMoveCountOption> moveCountOptions;
  final ValueChanged<GameMoveCountOption> onMoveSelected;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return ListView(
      children: [
        Text(
          'Hamle sayısını seç',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF3A3025),
          ),
        ),
        const SizedBox(height: 8),
        DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF1A5D57).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(
                  Icons.grid_4x4_rounded,
                  size: 16,
                  color: Color(0xFF1A5D57),
                ),
                const SizedBox(width: 6),
                Text(
                  '${option.gridLabel} • ${option.label}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A5D57),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        for (final GameMoveCountOption moveCountOption in moveCountOptions) ...[
          _MoveCountCard(
            key: Key('setup-move-${moveCountOption.moveLimit}'),
            moveCountOption: moveCountOption,
            onTap: () => onMoveSelected(moveCountOption),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _MoveCountCard extends StatefulWidget {
  const _MoveCountCard({
    super.key,
    required this.moveCountOption,
    required this.onTap,
  });

  final GameMoveCountOption moveCountOption;
  final VoidCallback onTap;

  @override
  State<_MoveCountCard> createState() => _MoveCountCardState();
}

class _MoveCountCardState extends State<_MoveCountCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Colors.white,
            border: Border.all(
              color: const Color(0xFF1A5D57).withValues(alpha: 0.12),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: <Widget>[
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: <Color>[Color(0xFF1A5D57), Color(0xFF2E8B7A)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Icon(
                      Icons.swipe_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '${widget.moveCountOption.moveLimit} Hamle',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF3A3025),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.moveCountOption.ctaLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF7A6F62),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.play_arrow_rounded,
                  color: Color(0xFF2E8B7A),
                  size: 28,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Session bootstrap (legacy - kept for routing compatibility)
// ─────────────────────────────────────────────────────────────

class GameSessionBootstrapScreen extends StatelessWidget {
  const GameSessionBootstrapScreen({super.key, required this.config});

  final GameConfig config;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Oyun Başladı')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.grid_view_rounded,
                  size: 56,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 20),
                Text(
                  'Oturum hazır',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Board foundation bir sonraki planda burada yükselecek. Bu planda seçilen oturum ayarları güvenilir şekilde oyuna aktarıldı.',
                  style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                _SessionSummaryRow(
                  label: 'Zorluk',
                  value: config.difficultyLabel,
                ),
                const SizedBox(height: 12),
                _SessionSummaryRow(label: 'Grid', value: config.gridLabel),
                const SizedBox(height: 12),
                _SessionSummaryRow(
                  label: 'Hamle',
                  value: '${config.moveLimit}',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SessionSummaryRow extends StatelessWidget {
  const _SessionSummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(value, style: theme.textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}
