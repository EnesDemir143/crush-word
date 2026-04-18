import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:crush_word/src/core/gameplay/models/game_session.dart';
import 'package:crush_word/src/core/gameplay/services/word_validator.dart';
import 'package:crush_word/src/core/models/game_config.dart';
import 'package:crush_word/src/features/game/game_controller.dart';
import 'package:crush_word/src/features/game/widgets/game_header.dart';
import 'package:crush_word/src/features/game/widgets/letter_grid.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.config, this.controller});

  final GameConfig config;
  final GameController? controller;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? GameController(config: widget.config);
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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, _) {
        final GameSession? session = _controller.session;

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            title: Text('${widget.config.difficultyLabel} Oyun Tahtası'),
          ),
          extendBodyBehindAppBar: false,
          body: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  Color(0xFFF6EFE3),
                  Color(0xFFEDE6D8),
                  Color(0xFFDCE8E0),
                ],
              ),
            ),
            child: Stack(
              children: <Widget>[
                const _BackgroundGlow(
                  alignment: Alignment.topLeft,
                  color: Color(0x3395C9A3),
                  diameter: 240,
                ),
                const _BackgroundGlow(
                  alignment: Alignment.centerRight,
                  color: Color(0x33D29A5A),
                  diameter: 280,
                ),
                const _BackgroundGlow(
                  alignment: Alignment.bottomLeft,
                  color: Color(0x33538F87),
                  diameter: 220,
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: switch ((session, _controller.isLoading)) {
                      (null, true) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      (null, false) => _GameLoadError(
                        message:
                            _controller.errorMessage ??
                            'Oyun tahtası yüklenemedi.',
                        onRetry: () => _controller.load(force: true),
                      ),
                      _ => _GameBody(
                        session: session!,
                        controller: _controller,
                      ),
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _GameBody extends StatelessWidget {
  const _GameBody({required this.session, required this.controller});

  final GameSession session;
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final InvalidAttemptFeedback? feedback = controller.lastInvalidFeedback;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool isWide = constraints.maxWidth >= 900;
        final bool isMedium = constraints.maxWidth >= 640;
        final bool useCompactChrome = !isMedium || constraints.maxHeight < 620;

        if (isWide) {
          return Row(
            children: <Widget>[
              Expanded(
                flex: 7,
                child: _BoardStage(
                  session: session,
                  controller: controller,
                  boardSide: _resolveWideBoardSide(constraints),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 5,
                child: Column(
                  children: <Widget>[
                    GameHeader(
                      config: session.config,
                      score: controller.score,
                      movesLeft: controller.movesLeft,
                      activeWord: controller.selectedWord,
                      compact: constraints.maxHeight < 760,
                    ),
                    const SizedBox(height: 20),
                    if (feedback != null)
                      _InvalidFeedbackBanner(feedback: feedback),
                  ],
                ),
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            GameHeader(
              config: session.config,
              score: controller.score,
              movesLeft: controller.movesLeft,
              activeWord: controller.selectedWord,
              compact: useCompactChrome,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _BoardStage(session: session, controller: controller),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 44,
              child: feedback != null
                  ? _InvalidFeedbackBanner(feedback: feedback)
                  : null,
            ),
          ],
        );
      },
    );
  }

  double _resolveWideBoardSide(BoxConstraints constraints) {
    const double boardChrome = 28;
    return math.min(
      680,
      math.min(
        constraints.maxHeight - boardChrome,
        (constraints.maxWidth * 0.58) - boardChrome,
      ),
    );
  }
}

class _BoardStage extends StatelessWidget {
  const _BoardStage({
    required this.session,
    required this.controller,
    this.boardSide,
  });

  final GameSession session;
  final GameController controller;
  final double? boardSide;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double stagePadding = session.gridSize >= 10 ? 6 : 10;

    final Widget gridContent = RepaintBoundary(
      child: LetterGrid(
        key: const Key('game-letter-grid'),
        session: session,
        selectedCellIds: controller.selectedCellIds,
        onSelectionStart: controller.startSelection,
        onSelectionExtend: controller.extendSelection,
        onSelectionEnd: () => unawaited(controller.endSelection()),
      ),
    );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        // Determine the board side length.
        // For wide/desktop layout, use the provided fixed value.
        // For narrow/phone layout, fill the available width fully.
        final double side;
        if (boardSide != null) {
          side = math.max(0, boardSide!);
        } else {
          final double availableWidth = constraints.maxWidth;
          final double availableHeight = constraints.maxHeight;
          // Fill the width, accounting for stage padding on each side.
          side = math.min(
            availableWidth - (stagePadding * 2),
            availableHeight - (stagePadding * 2),
          );
        }
        final double safeSide = math.max(0, side);

        return Center(
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOutCubic,
            tween: Tween<double>(begin: 0.96, end: 1),
            builder: (BuildContext context, double scale, Widget? child) {
              return Transform.scale(scale: scale, child: child);
            },
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(36),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[Color(0xFFF8F4EC), Color(0xFFF0E6D6)],
                ),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                    blurRadius: 30,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(stagePadding),
                child: SizedBox.square(dimension: safeSide, child: gridContent),
              ),
            ),
          ),
        );
      },
    );
  }
}



class _InvalidFeedbackBanner extends StatelessWidget {
  const _InvalidFeedbackBanner({required this.feedback});

  final InvalidAttemptFeedback feedback;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String displayMessage = switch (feedback.reason) {
      WordValidationReason.tooShort =>
        'En az 3 harf gerekli',
      WordValidationReason.notInDictionary =>
        '"${feedback.word}" sözlükte bulunamadı',
      _ => 'Geçersiz kelime',
    };

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFFDE8E8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFF5C6C6),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(
                Icons.info_outline_rounded,
                color: Color(0xFFB91C1C),
                size: 18,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  displayMessage,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFFB91C1C),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackgroundGlow extends StatelessWidget {
  const _BackgroundGlow({
    required this.alignment,
    required this.color,
    required this.diameter,
  });

  final Alignment alignment;
  final Color color;
  final double diameter;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: IgnorePointer(
        child: Container(
          width: diameter,
          height: diameter,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: <Color>[color, Colors.transparent],
            ),
          ),
        ),
      ),
    );
  }
}

class _GameLoadError extends StatelessWidget {
  const _GameLoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  Icons.warning_amber_rounded,
                  size: 56,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Tahta hazırlanamadı',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: onRetry,
                  child: const Text('Tekrar Dene'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
