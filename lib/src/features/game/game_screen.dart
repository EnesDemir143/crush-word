import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:crush_word/src/core/gameplay/models/game_session.dart';
import 'package:crush_word/src/core/gameplay/services/word_validator.dart';
import 'package:crush_word/src/core/models/game_config.dart';
import 'package:crush_word/src/features/game/game_controller.dart';
import 'package:crush_word/src/features/game/exit_confirmation_dialog.dart';
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
  bool _allowPop = false;

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
        final bool requiresExitConfirmation =
            _controller.hasSession && !_controller.isGameOver && !_allowPop;

        return PopScope<void>(
          canPop: !requiresExitConfirmation,
          onPopInvokedWithResult: (bool didPop, void _) {
            if (!didPop && requiresExitConfirmation) {
              unawaited(_handleExitAttempt());
            }
          },
          child: Scaffold(
            backgroundColor: const Color(0xFFF6EFE3),
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              foregroundColor: const Color(0xFF3A3025),
              elevation: 0,
            ),
            extendBodyBehindAppBar: true,
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
                          onReturnHome: _returnHome,
                        ),
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleExitAttempt() async {
    final bool shouldExit = await showExitConfirmationDialog(context) ?? false;

    if (!shouldExit) {
      return;
    }

    await _controller.confirmExit();
    if (!mounted) {
      return;
    }

    _returnHome();
  }

  void _returnHome() {
    if (!_allowPop) {
      setState(() {
        _allowPop = true;
      });
    }

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }

    Navigator.of(context).maybePop();
  }
}

class _GameBody extends StatelessWidget {
  const _GameBody({
    required this.session,
    required this.controller,
    required this.onReturnHome,
  });

  final GameSession session;
  final GameController controller;
  final VoidCallback onReturnHome;

  bool get _isGameOver => controller.isGameOver;

  @override
  Widget build(BuildContext context) {
    final InvalidAttemptFeedback? feedback = controller.lastInvalidFeedback;

    return Stack(
      children: <Widget>[
        // ── Main game layout ──────────────────────
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool isWide = constraints.maxWidth >= 900;
            final bool isMedium = constraints.maxWidth >= 640;
            final bool useCompactChrome =
                !isMedium || constraints.maxHeight < 620;

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
                          lastWordScore: controller.lastWordScore,
                        ),
                        const SizedBox(height: 12),
                        _AnimatedFeedback(feedback: feedback),
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
                  lastWordScore: controller.lastWordScore,
                ),
                _AnimatedFeedback(feedback: feedback),
                const SizedBox(height: 8),
                Expanded(
                  child: _BoardStage(session: session, controller: controller),
                ),
              ],
            );
          },
        ),

        // ── Game over overlay ─────────────────────
        if (_isGameOver)
          _GameOverOverlay(
            score: controller.score,
            config: session.config,
            onReturnHome: onReturnHome,
          ),
      ],
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

class _BoardStage extends StatefulWidget {
  const _BoardStage({
    required this.session,
    required this.controller,
    this.boardSide,
  });

  final GameSession session;
  final GameController controller;
  final double? boardSide;

  @override
  State<_BoardStage> createState() => _BoardStageState();
}

class _BoardStageState extends State<_BoardStage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shakeController;
  late final Animation<double> _shakeOffset;

  InvalidAttemptFeedback? _lastFeedback;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeOffset = TweenSequence<double>(
      <TweenSequenceItem<double>>[
        TweenSequenceItem<double>(
          tween: Tween<double>(begin: 0, end: 8),
          weight: 15,
        ),
        TweenSequenceItem<double>(
          tween: Tween<double>(begin: 8, end: -6),
          weight: 20,
        ),
        TweenSequenceItem<double>(
          tween: Tween<double>(begin: -6, end: 4),
          weight: 20,
        ),
        TweenSequenceItem<double>(
          tween: Tween<double>(begin: 4, end: -2),
          weight: 20,
        ),
        TweenSequenceItem<double>(
          tween: Tween<double>(begin: -2, end: 0),
          weight: 25,
        ),
      ],
    ).animate(CurvedAnimation(parent: _shakeController, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(covariant _BoardStage oldWidget) {
    super.didUpdateWidget(oldWidget);

    final InvalidAttemptFeedback? newFeedback =
        widget.controller.lastInvalidFeedback;
    if (newFeedback != null && newFeedback != _lastFeedback) {
      _lastFeedback = newFeedback;
      _shakeController
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double stagePadding = widget.session.gridSize >= 10 ? 6 : 10;

    final Widget gridContent = RepaintBoundary(
      child: LetterGrid(
        key: const Key('game-letter-grid'),
        session: widget.session,
        selectedCellIds: widget.controller.selectedCellIds,
        onSelectionStart: widget.controller.startSelection,
        onSelectionExtend: widget.controller.extendSelection,
        onSelectionEnd: () => unawaited(widget.controller.endSelection()),
        lastRemovedCellIds: widget.controller.lastRemovedCellIds,
      ),
    );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double side;
        if (widget.boardSide != null) {
          side = math.max(0, widget.boardSide!);
        } else {
          final double availableWidth = constraints.maxWidth;
          final double availableHeight = constraints.maxHeight;
          side = math.min(
            availableWidth - (stagePadding * 2),
            availableHeight - (stagePadding * 2),
          );
        }
        final double safeSide = math.max(0, side);

        return Center(
          child: AnimatedBuilder(
            animation: _shakeController,
            builder: (BuildContext context, Widget? child) {
              return Transform.translate(
                offset: Offset(_shakeOffset.value, 0),
                child: child,
              );
            },
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
                  child: SizedBox.square(
                    dimension: safeSide,
                    child: gridContent,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AnimatedFeedback extends StatelessWidget {
  const _AnimatedFeedback({required this.feedback});

  final InvalidAttemptFeedback? feedback;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.3),
            end: Offset.zero,
          ).animate(animation),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: feedback != null
          ? _InvalidFeedbackBanner(
              key: ValueKey<String>(feedback!.word),
              feedback: feedback!,
            )
          : const SizedBox.shrink(key: ValueKey<String>('empty')),
    );
  }
}

class _InvalidFeedbackBanner extends StatelessWidget {
  const _InvalidFeedbackBanner({super.key, required this.feedback});

  final InvalidAttemptFeedback feedback;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String displayMessage = switch (feedback.reason) {
      WordValidationReason.tooShort => 'En az 3 harf gerekli',
      WordValidationReason.notInDictionary =>
        '"${feedback.word}" sözlükte bulunamadı',
      _ => 'Geçersiz kelime',
    };

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFFDE8E8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFF5C6C6)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(
                Icons.info_outline_rounded,
                color: Color(0xFFB91C1C),
                size: 16,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  displayMessage,
                  style: theme.textTheme.bodySmall?.copyWith(
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

class _GameOverOverlay extends StatefulWidget {
  const _GameOverOverlay({
    required this.score,
    required this.config,
    required this.onReturnHome,
  });

  final int score;
  final GameConfig config;
  final VoidCallback onReturnHome;

  @override
  State<_GameOverOverlay> createState() => _GameOverOverlayState();
}

class _GameOverOverlayState extends State<_GameOverOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _backgroundOpacity;
  late final Animation<double> _cardScale;
  late final Animation<double> _cardOpacity;
  late final Animation<double> _scoreProgress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _backgroundOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.3, curve: Curves.easeOut),
      ),
    );
    _cardScale = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.15, 0.5, curve: Curves.elasticOut),
      ),
    );
    _cardOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.15, 0.4)),
    );
    _scoreProgress = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.9, curve: Curves.easeOutCubic),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, _) {
        return Positioned.fill(
          child: ColoredBox(
            color: Color.fromRGBO(0, 0, 0, 0.45 * _backgroundOpacity.value),
            child: Center(
              child: Opacity(
                opacity: _cardOpacity.value,
                child: Transform.scale(
                  scale: _cardScale.value,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: <Color>[Color(0xFFFFFCF7), Color(0xFFF6EFE2)],
                        ),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: const Color(
                              0xFF0F172A,
                            ).withValues(alpha: 0.15),
                            blurRadius: 40,
                            offset: const Offset(0, 20),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: <Color>[
                                    Color(0xFFD4A017),
                                    Color(0xFFE6B533),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: const Padding(
                                padding: EdgeInsets.all(16),
                                child: Icon(
                                  Icons.emoji_events_rounded,
                                  size: 40,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Oyun Bitti!',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF3A3025),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${widget.config.difficultyLabel} • ${widget.config.gridLabel}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF7A6F62),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              '${(_scoreProgress.value * widget.score).round()}',
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFD4A017),
                              ),
                            ),
                            const Text(
                              'PUAN',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF7A6F62),
                                letterSpacing: 3,
                              ),
                            ),
                            const SizedBox(height: 28),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: widget.onReturnHome,
                                child: const Text('Ana Menüye Dön'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
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
