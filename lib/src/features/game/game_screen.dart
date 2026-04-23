import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:crush_word/src/core/gameplay/models/game_session.dart';
import 'package:crush_word/src/core/gameplay/services/word_validator.dart';
import 'package:crush_word/src/core/models/game_config.dart';
import 'package:crush_word/src/features/game/game_controller.dart';
import 'package:crush_word/src/features/game/exit_confirmation_dialog.dart';
import 'package:crush_word/src/features/game/widgets/game_header.dart';
import 'package:crush_word/src/features/game/widgets/joker_bar.dart';
import 'package:crush_word/src/features/game/widgets/letter_grid.dart';
import 'package:crush_word/src/features/market/market_controller.dart';
import 'package:crush_word/src/core/presentation/joker_art.dart';

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
            body: Stack(
              children: <Widget>[
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/gameplay_background.png',
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: <Color>[
                          Color(0x66FFF8EE),
                          Color(0x52FFF4E2),
                          Color(0x5EE8F8FF),
                        ],
                      ),
                    ),
                  ),
                ),
                const _BackgroundGlow(
                  alignment: Alignment.topLeft,
                  color: Color(0x2695C9A3),
                  diameter: 240,
                ),
                const _BackgroundGlow(
                  alignment: Alignment.centerRight,
                  color: Color(0x26D29A5A),
                  diameter: 280,
                ),
                const _BackgroundGlow(
                  alignment: Alignment.bottomLeft,
                  color: Color(0x22538F87),
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

  static const double _regularTopChromeHeight = 124;
  static const double _compactTopChromeHeight = 104;
  static const double _regularJokerChromeHeight = 112;
  static const double _compactJokerChromeHeight = 100;
  static const double _regularTopToBoardGap = 8;
  static const double _compactTopToBoardGap = 6;
  static const double _regularBoardToJokerGap = 12;
  static const double _compactBoardToJokerGap = 8;

  @override
  Widget build(BuildContext context) {
    final InvalidAttemptFeedback? feedback = controller.lastInvalidFeedback;
    final availableJokers = controller.availableJokers;
    final Widget jokerBar = JokerBar(
      jokers: availableJokers,
      inventoryById: controller.jokerInventory,
      activeJokerId: controller.activeJokerId,
      helperText: controller.jokerHintText,
      enabled: !controller.isLoading && !controller.isGameOver,
      onJokerPressed: (String jokerId) {
        unawaited(controller.activateJoker(jokerId));
      },
      onJokerBuyRequested: (String jokerId) {
        unawaited(_buyJokerInGame(context, jokerId));
      },
    );

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
              return Column(
                children: <Widget>[
                  Expanded(
                    child: Row(
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
                                score: controller.score,
                                movesLeft: controller.movesLeft,
                                activeWord: controller.selectedWord,
                                compact: constraints.maxHeight < 760,
                                lastWordScore: controller.lastWordScore,
                                comboCount: controller.lastComboCount,
                                playableWordCount: controller.playableWordCount,
                              ),
                              const SizedBox(height: 12),
                              _AnimatedFeedback(feedback: feedback),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  jokerBar,
                ],
              );
            }

            final Widget header = GameHeader(
              score: controller.score,
              movesLeft: controller.movesLeft,
              activeWord: controller.selectedWord,
              compact: useCompactChrome,
              lastWordScore: controller.lastWordScore,
              comboCount: controller.lastComboCount,
              playableWordCount: controller.playableWordCount,
            );
            final _NarrowGameLayoutMetrics layout = _resolveNarrowGameLayout(
              constraints: constraints,
              useCompactChrome: useCompactChrome,
              gridSize: session.gridSize,
              hasJokerBar: availableJokers.isNotEmpty,
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                SizedBox(
                  height: layout.topChromeHeight,
                  child: _FixedChromeSlot(
                    key: const Key('game-top-chrome-slot'),
                    alignment: Alignment.bottomCenter,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        header,
                        _AnimatedFeedback(feedback: feedback),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: layout.topToBoardGap),
                SizedBox(
                  height: layout.boardOuterSide,
                  child: _BoardStage(
                    session: session,
                    controller: controller,
                    boardSide: layout.boardSide,
                  ),
                ),
                SizedBox(height: layout.boardToJokerGap),
                SizedBox(
                  height: layout.bottomChromeHeight,
                  child: availableJokers.isEmpty
                      ? const SizedBox.shrink()
                      : _FixedChromeSlot(
                          key: const Key('game-bottom-chrome-slot'),
                          alignment: Alignment.topCenter,
                          child: jokerBar,
                        ),
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

  _NarrowGameLayoutMetrics _resolveNarrowGameLayout({
    required BoxConstraints constraints,
    required bool useCompactChrome,
    required int gridSize,
    required bool hasJokerBar,
  }) {
    final double stagePadding = _boardStagePaddingForGridSize(gridSize);
    final double maxBoardSideByWidth = math.max(
      0,
      constraints.maxWidth - (stagePadding * 2),
    );
    final double targetBoardOuterSide =
        maxBoardSideByWidth + (stagePadding * 2);
    final double baseTopChromeHeight = useCompactChrome
        ? _compactTopChromeHeight
        : _regularTopChromeHeight;
    final double baseBottomChromeHeight = hasJokerBar
        ? (useCompactChrome
              ? _compactJokerChromeHeight
              : _regularJokerChromeHeight)
        : 0;
    final double topToBoardGap = useCompactChrome
        ? _compactTopToBoardGap
        : _regularTopToBoardGap;
    final double boardToJokerGap = hasJokerBar
        ? (useCompactChrome ? _compactBoardToJokerGap : _regularBoardToJokerGap)
        : 0;

    final double baseReservedHeight =
        baseTopChromeHeight +
        topToBoardGap +
        targetBoardOuterSide +
        boardToJokerGap +
        baseBottomChromeHeight;

    if (!constraints.maxHeight.isFinite || constraints.maxHeight <= 0) {
      return _NarrowGameLayoutMetrics(
        topChromeHeight: baseTopChromeHeight,
        topToBoardGap: topToBoardGap,
        boardSide: maxBoardSideByWidth,
        stagePadding: stagePadding,
        boardToJokerGap: boardToJokerGap,
        bottomChromeHeight: baseBottomChromeHeight,
      );
    }

    if (baseReservedHeight <= constraints.maxHeight) {
      final double extraHeight = constraints.maxHeight - baseReservedHeight;
      final double balancedSlack = extraHeight / 2;

      return _NarrowGameLayoutMetrics(
        topChromeHeight: baseTopChromeHeight + balancedSlack,
        topToBoardGap: topToBoardGap,
        boardSide: maxBoardSideByWidth,
        stagePadding: stagePadding,
        boardToJokerGap: boardToJokerGap,
        bottomChromeHeight: baseBottomChromeHeight + balancedSlack,
      );
    }

    final double availableBoardOuterSide = math.max(
      0,
      constraints.maxHeight -
          baseTopChromeHeight -
          topToBoardGap -
          boardToJokerGap -
          baseBottomChromeHeight,
    );
    final double boardSide = math.min(
      maxBoardSideByWidth,
      math.max(0, availableBoardOuterSide - (stagePadding * 2)),
    );

    return _NarrowGameLayoutMetrics(
      topChromeHeight: baseTopChromeHeight,
      topToBoardGap: topToBoardGap,
      boardSide: boardSide,
      stagePadding: stagePadding,
      boardToJokerGap: boardToJokerGap,
      bottomChromeHeight: baseBottomChromeHeight,
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

  Future<void> _buyJokerInGame(BuildContext context, String jokerId) async {
    final joker = controller.availableJokers.firstWhere((j) => j.id == jokerId);

    // Briefly show a loading indicator while we check gold balance
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) =>
          const Center(child: CircularProgressIndicator()),
    );

    final MarketController market = MarketController();
    await market.load();

    if (!context.mounted) {
      market.dispose();
      return;
    }

    // Dismiss the loader
    Navigator.of(context).pop();

    final int currentGold = market.goldBalance;
    final bool canAfford = currentGold >= joker.cost;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
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
                    color: const Color(0xFF0F172A).withValues(alpha: 0.15),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    DecoratedBox(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: <Color>[Color(0xFF1A5D57), Color(0xFF2E8B7A)],
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: JokerArtImage(
                          jokerId: joker.id,
                          size: 48,
                          circular: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '${joker.name} Satın Al',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF3A3025),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Bu jokerden kalmadı. ${joker.cost} Altın karşılığında hemen satın alıp oynamaya devam edebilirsin.',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF7A6F62),
                        height: 1.45,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDF8F0),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE5D4BA)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          const Text(
                            'Bakiyen:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF6E5432),
                            ),
                          ),
                          Row(
                            children: <Widget>[
                              const Icon(
                                Icons.monetization_on_rounded,
                                color: Color(0xFF9A6B00),
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$currentGold',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: canAfford
                                      ? const Color(0xFF6E5432)
                                      : const Color(0xFFB91C1C),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF7A6F62),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                            child: const Text(
                              'İptal',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: canAfford
                                ? () => Navigator.of(ctx).pop(true)
                                : null,
                            icon: const Icon(
                              Icons.shopping_cart_checkout_rounded,
                              size: 18,
                            ),
                            label: const Text(
                              'Satın Al',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    if (confirmed != true) {
      market.dispose();
      return;
    }

    if (!context.mounted) {
      market.dispose();
      return;
    }

    // Show loading overlay during purchase
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) =>
          const Center(child: CircularProgressIndicator()),
    );

    final MarketPurchaseStatus status = await market.purchaseJoker(joker);
    market.dispose();

    if (!context.mounted) return;

    // Close loading overlay
    Navigator.of(context).pop();

    if (status == MarketPurchaseStatus.success) {
      await controller.refreshInventory();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('${joker.name} alındı! Kullanabilirsin.')),
        );
    } else if (status == MarketPurchaseStatus.insufficientGold) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Yeterli altının yok.')));
    } else {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('İşlem devam ediyor.')));
    }
  }
}

class _NarrowGameLayoutMetrics {
  const _NarrowGameLayoutMetrics({
    required this.topChromeHeight,
    required this.topToBoardGap,
    required this.boardSide,
    required this.stagePadding,
    required this.boardToJokerGap,
    required this.bottomChromeHeight,
  });

  final double topChromeHeight;
  final double topToBoardGap;
  final double boardSide;
  final double stagePadding;
  final double boardToJokerGap;
  final double bottomChromeHeight;

  double get boardOuterSide => boardSide + (stagePadding * 2);
}

class _FixedChromeSlot extends StatelessWidget {
  const _FixedChromeSlot({
    super.key,
    required this.child,
    required this.alignment,
  });

  final Widget child;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return ClipRect(
          child: Align(
            alignment: alignment,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: alignment,
              child: SizedBox(width: constraints.maxWidth, child: child),
            ),
          ),
        );
      },
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
    with TickerProviderStateMixin {
  late final AnimationController _shakeController;
  late final AnimationController _impactController;
  late final Animation<double> _shakeOffset;
  late final Animation<double> _impactScale;
  late final Animation<double> _impactGlow;

  InvalidAttemptFeedback? _lastFeedback;
  int _lastBoardEffectToken = 0;

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

    _impactController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );
    _impactScale =
        TweenSequence<double>(<TweenSequenceItem<double>>[
          TweenSequenceItem<double>(
            tween: Tween<double>(begin: 1, end: 0.975),
            weight: 24,
          ),
          TweenSequenceItem<double>(
            tween: Tween<double>(begin: 0.975, end: 1.02),
            weight: 38,
          ),
          TweenSequenceItem<double>(
            tween: Tween<double>(begin: 1.02, end: 1),
            weight: 38,
          ),
        ]).animate(
          CurvedAnimation(
            parent: _impactController,
            curve: Curves.easeOutCubic,
          ),
        );
    _impactGlow =
        TweenSequence<double>(<TweenSequenceItem<double>>[
          TweenSequenceItem<double>(
            tween: Tween<double>(begin: 0, end: 1),
            weight: 35,
          ),
          TweenSequenceItem<double>(
            tween: Tween<double>(begin: 1, end: 0),
            weight: 65,
          ),
        ]).animate(
          CurvedAnimation(
            parent: _impactController,
            curve: Curves.easeOutCubic,
          ),
        );
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

    if (widget.controller.lastBoardEffectToken != _lastBoardEffectToken) {
      _lastBoardEffectToken = widget.controller.lastBoardEffectToken;
      _impactController
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _impactController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double stagePadding = _boardStagePaddingForGridSize(
      widget.session.gridSize,
    );

    final Widget gridContent = RepaintBoundary(
      child: LetterGrid(
        key: const Key('game-letter-grid'),
        session: widget.session,
        selectedCellIds: widget.controller.selectedCellIds,
        onSelectionStart: widget.controller.startSelection,
        onSelectionExtend: widget.controller.extendSelection,
        onSelectionEnd: () => unawaited(widget.controller.endSelection()),
        lastRemovedCellIds: widget.controller.lastRemovedCellIds,
        effectToken: widget.controller.lastBoardEffectToken,
        comboCount: widget.controller.lastComboCount,
        createdPower: widget.controller.lastCreatedPower,
        activatedPowers: widget.controller.lastActivatedPowers,
        lastJokerEffectId: widget.controller.lastJokerEffectId,
        partyCastToken: widget.controller.partyCastToken,
        isPartyCasting: widget.controller.isPartyCasting,
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
                child: Transform.scale(
                  scale: _impactScale.value,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: const Color(
                            0xFFFCB44B,
                          ).withValues(alpha: 0.20 * _impactGlow.value),
                          blurRadius: 36 * _impactGlow.value,
                          spreadRadius: 8 * _impactGlow.value,
                        ),
                      ],
                    ),
                    child: child,
                  ),
                ),
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

double _boardStagePaddingForGridSize(int gridSize) => gridSize >= 10 ? 6 : 10;

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
