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
            appBar: AppBar(
              title: Text(
                _controller.step == GameSetupStep.difficulty
                    ? 'Yeni Oyun'
                    : 'Hamle Sayısı',
              ),
              leading: _controller.canStepBack
                  ? IconButton(
                      onPressed: _controller.returnToDifficultySelection,
                      icon: const Icon(Icons.arrow_back_rounded),
                    )
                  : null,
            ),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: _buildBody(context),
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
      return _MoveCountStep(option: option, onMoveSelected: _startGame);
    }

    return _DifficultyStep(
      options: _controller.difficultyOptions,
      onOptionSelected: _controller.selectDifficulty,
    );
  }
}

class _DifficultyStep extends StatelessWidget {
  const _DifficultyStep({
    required this.options,
    required this.onOptionSelected,
  });

  final List<GameSetupOption> options;
  final ValueChanged<GameSetupOption> onOptionSelected;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return ListView(
      children: [
        Text(
          'Grid boyutunu seç',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Kaynak dokümandaki birebir eşleşme uygulanır: 6x6 = Zor, 8x8 = Orta, 10x10 = Kolay.',
          style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
        ),
        const SizedBox(height: 24),
        for (final GameSetupOption option in options) ...[
          _SetupOptionCard(
            key: Key('setup-difficulty-${option.difficulty.name}'),
            title: option.gridLabel,
            badgeLabel: option.label,
            description:
                'Bu seçimden sonra yalnızca ${option.moveSummary} açılır.',
            onTap: () => onOptionSelected(option),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _MoveCountStep extends StatelessWidget {
  const _MoveCountStep({required this.option, required this.onMoveSelected});

  final GameSetupOption option;
  final ValueChanged<GameConfig> onMoveSelected;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return ListView(
      children: [
        Text(
          'Hamle sayısını seç',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '${option.gridLabel} secildi. Bu seviye ${option.label} olarak oynanır.',
          style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
        ),
        const SizedBox(height: 8),
        Text(
          'Sadece kaynak dokümandaki izinli hamle değerleri gösterilir.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        for (final int moveCount in option.moveCountOptions) ...[
          FilledButton(
            key: Key('setup-move-$moveCount'),
            onPressed: () =>
                onMoveSelected(option.toGameConfig(moveLimit: moveCount)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text('$moveCount hamle ile başla'),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _SetupOptionCard extends StatelessWidget {
  const _SetupOptionCard({
    super.key,
    required this.title,
    required this.badgeLabel,
    required this.description,
    required this.onTap,
  });

  final String title;
  final String badgeLabel;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Chip(label: Text(badgeLabel)),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                description,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
