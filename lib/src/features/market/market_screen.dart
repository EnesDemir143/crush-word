import 'dart:async';
import 'package:flutter/material.dart';

import 'package:crush_word/src/core/config/game_rules_config.dart';
import 'package:crush_word/src/core/presentation/joker_art.dart';
import 'package:crush_word/src/features/market/market_controller.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key, this.controller});

  final MarketController? controller;

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  late final MarketController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? MarketController();
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

  Future<void> _purchase(MarketJokerDefinition joker) async {
    final MarketPurchaseStatus status = await _controller.purchaseJoker(joker);

    if (!mounted) {
      return;
    }

    final String message = switch (status) {
      MarketPurchaseStatus.success => '${joker.name} envantere eklendi.',
      MarketPurchaseStatus.insufficientGold =>
        'Bu joker için yeterli altın yok.',
      MarketPurchaseStatus.busy => 'Satın alma işlemi zaten sürüyor.',
    };

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showJokerDetails(MarketJokerDefinition joker) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (BuildContext context, _) {
            return AlertDialog(
              titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
              contentPadding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
              title: Row(
                children: <Widget>[
                  _JokerArtwork(jokerId: joker.id),
                  const SizedBox(width: 12),
                  Expanded(child: Text(joker.name)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      _InfoChip(
                        key: Key('market-dialog-price-${joker.id}'),
                        icon: Icons.toll_rounded,
                        label: '${joker.cost}',
                      ),
                      _InfoChip(
                        key: Key('market-dialog-stock-${joker.id}'),
                        icon: Icons.inventory_2_rounded,
                        label: '${_controller.quantityFor(joker.id)}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    joker.description,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: Color(0xFF3A3025),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _DetailBlock(title: 'Kullanım amacı', content: joker.purpose),
                  const SizedBox(height: 16),
                  _DetailBlock(title: 'Kullanım şekli', content: joker.usage),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Kapat'),
                ),
                FilledButton.icon(
                  key: Key('market-dialog-buy-${joker.id}'),
                  onPressed:
                      _controller.canPurchase(joker) &&
                          !_controller.isPurchasing(joker.id)
                      ? () => _purchase(joker)
                      : null,
                  icon: _controller.isPurchasing(joker.id)
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.shopping_cart_checkout_rounded),
                  label: Text(
                    _controller.isPurchasing(joker.id)
                        ? 'İşleniyor'
                        : 'Satın Al',
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showHowItWorks(MarketJokerDefinition joker) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) => _HowItWorksDialog(joker: joker),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: const Color(0xFF3A3025),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Market',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF3A3025),
          ),
        ),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (BuildContext context, _) {
                return _GoldHeaderChip(
                  goldBalance: _controller.goldBalance,
                  onDebugAddGold: () async {
                    final int nextBalance = _controller.goldBalance + 10000;
                    await _controller.setGoldBalanceForDebug(nextBalance);
                    if (!context.mounted) {
                      return;
                    }
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        const SnackBar(content: Text('+10000 altın eklendi.')),
                      );
                  },
                );
              },
            ),
          ),
        ],
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
            padding: const EdgeInsets.fromLTRB(24, kToolbarHeight + 20, 24, 24),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (BuildContext context, _) => _buildBody(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_controller.isLoading && _controller.marketRules == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_controller.error != null && _controller.marketRules == null) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'Market yüklenemedi.',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Joker kataloğu veya ekonomi verisi okunurken hata oluştu.',
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

    return ListView(
      children: <Widget>[
        for (final MarketJokerDefinition joker in _controller.jokers) ...[
          _JokerCard(
            joker: joker,
            quantity: _controller.quantityFor(joker.id),
            isPurchasing: _controller.isPurchasing(joker.id),
            canPurchase: _controller.canPurchase(joker),
            onShowDetails: () => _showJokerDetails(joker),
            onPurchase: () => _purchase(joker),
            onShowHowItWorks: () => _showHowItWorks(joker),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

// ── How It Works Dialog ────────────────────────────────────────

class _HowItWorksDialog extends StatefulWidget {
  const _HowItWorksDialog({required this.joker});

  final MarketJokerDefinition joker;

  @override
  State<_HowItWorksDialog> createState() => _HowItWorksDialogState();
}

class _HowItWorksDialogState extends State<_HowItWorksDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  int _step = 0;
  Timer? _stepTimer;
  bool _isPlaying = false;

  static const int _totalSteps = 4;
  static const Duration _stepDuration = Duration(milliseconds: 1400);

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: _stepDuration);
    // Auto-start on open
    WidgetsBinding.instance.addPostFrameCallback((_) => _play());
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    _animCtrl.dispose();
    super.dispose();
  }

  void _play() {
    if (_isPlaying) return;
    setState(() {
      _step = 0;
      _isPlaying = true;
    });
    _scheduleNextStep();
  }

  void _scheduleNextStep() {
    _stepTimer?.cancel();
    _animCtrl
      ..reset()
      ..forward();
    _stepTimer = Timer(_stepDuration, () {
      if (!mounted) return;
      setState(() {
        _step = (_step + 1) % _totalSteps;
      });
      if (_step != 0) {
        _scheduleNextStep();
      } else {
        setState(() => _isPlaying = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFFDF8F0),
          borderRadius: BorderRadius.circular(28),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 32,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // Header
              Row(
                children: <Widget>[
                  _JokerArtwork(jokerId: widget.joker.id),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          widget.joker.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF2F261D),
                          ),
                        ),
                        const Text(
                          'Nasıl Çalışır?',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF7A6F62),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    color: const Color(0xFF7A6F62),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Animation area
              SizedBox(
                height: 180,
                child: AnimatedBuilder(
                  animation: _animCtrl,
                  builder: (BuildContext context, _) {
                    return _JokerAnimationScene(
                      jokerId: widget.joker.id,
                      step: _step,
                      progress: _animCtrl.value,
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              // Step description
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _stepLabel(widget.joker.id, _step),
                  key: ValueKey<String>('${widget.joker.id}-$_step'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: Color(0xFF3A3025),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Step dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  for (int i = 0; i < _totalSteps; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: _step == i ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _step == i
                            ? const Color(0xFF4A3B6B)
                            : const Color(0xFFCEC3B4),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              // Replay button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isPlaying ? null : _play,
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('Tekrar İzle'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _stepLabel(String jokerId, int step) {
    const Map<String, List<String>> labels = <String, List<String>>{
      'fish': <String>[
        '1. Balık jokeri seçilir',
        '2. Gridde rastgele 3 harf hedeflenir',
        '3. Seçilen harfler patlar ve yok olur',
        '4. Üstteki harfler aşağı düşer',
      ],
      'wheel': <String>[
        '1. Tekerlek jokeri seçilir',
        '2. Gridde bir harf seçilir (hedef)',
        '3. Hedefin tüm satırı ve sütunu yok olur',
        '4. Kalan harfler yerçekimiyle düşer',
      ],
      'lollipop_breaker': <String>[
        '1. Lolipop Kırıcı jokeri seçilir',
        '2. Kaldırılmak istenen tek harf seçilir',
        '3. Yalnızca o harf yok edilir',
        '4. Üstteki harfler aşağıya kayar',
      ],
      'free_swap': <String>[
        '1. Serbest Değiştirme jokeri seçilir',
        '2. Birinci harf seçilir',
        '3. Komşu ikinci harf seçilir',
        '4. İki harf yer değiştirir',
      ],
      'shuffle_letters': <String>[
        '1. Harf Karıştırma jokeri seçilir',
        '2. Mevcut grid düzeni alınır',
        '3. Harfler rastgele konumlara dağıtılır',
        '4. Yeni düzenle oyuna devam edilir',
      ],
      'party_booster': <String>[
        '1. Parti Güçlendiricisi seçilir',
        '2. Tüm grid harfleri silinir',
        '3. Yeni harfler yukarıdan aşağıya düşer',
        '4. Tamamen yeni bir grid oluşur',
      ],
    };

    final List<String>? jokerLabels = labels[jokerId];
    if (jokerLabels == null || step >= jokerLabels.length) {
      return '';
    }
    return jokerLabels[step];
  }
}

// ── Joker Animation Scene ──────────────────────────────────────

class _JokerAnimationScene extends StatelessWidget {
  const _JokerAnimationScene({
    required this.jokerId,
    required this.step,
    required this.progress,
  });

  final String jokerId;
  final int step;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return switch (jokerId) {
      'fish' => _FishScene(step: step, progress: progress),
      'wheel' => _WheelScene(step: step, progress: progress),
      'lollipop_breaker' => _LollipopScene(step: step, progress: progress),
      'free_swap' => _FreeSwapScene(step: step, progress: progress),
      'shuffle_letters' => _ShuffleScene(step: step, progress: progress),
      'party_booster' => _PartyScene(step: step, progress: progress),
      _ => const SizedBox.shrink(),
    };
  }
}

// ── Shared grid cell widget ─────────────────────────────────────

class _GridCell extends StatelessWidget {
  const _GridCell({
    required this.letter,
    this.highlighted = false,
    this.fading = false,
    this.swapped = false,
  });

  final String letter;
  final bool highlighted;
  final bool fading;
  final bool swapped;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;
    if (fading) {
      bg = const Color(0xFFFF6B6B).withValues(alpha: 0.7);
      text = Colors.white;
    } else if (highlighted) {
      bg = const Color(0xFF4A3B6B);
      text = Colors.white;
    } else if (swapped) {
      bg = const Color(0xFF2E8B7A);
      text = Colors.white;
    } else {
      bg = const Color(0xFFF0E8D8);
      text = const Color(0xFF3A3025);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 32,
      height: 32,
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        boxShadow: highlighted || fading
            ? <BoxShadow>[
                BoxShadow(
                  color: bg.withValues(alpha: 0.5),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Center(
        child: Text(
          letter,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: text,
          ),
        ),
      ),
    );
  }
}

// ── Scene: Fish (random cells) ─────────────────────────────────

class _FishScene extends StatelessWidget {
  const _FishScene({required this.step, required this.progress});

  final int step;
  final double progress;

  @override
  Widget build(BuildContext context) {
    // 4x4 mini grid. Cells 1,6,11 are "targeted" by fish.
    const List<String> letters = <String>[
      'K',
      'E',
      'L',
      'İ',
      'M',
      'E',
      'L',
      'E',
      'R',
      'A',
      'N',
      'A',
      'S',
      'O',
      'R',
      'U',
    ];
    const Set<int> targeted = <int>{1, 6, 10};

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        for (int row = 0; row < 4; row++)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              for (int col = 0; col < 4; col++)
                Builder(
                  builder: (BuildContext context) {
                    final int idx = row * 4 + col;
                    final bool isTargeted = targeted.contains(idx);
                    // step 1: highlight targeted
                    // step 2+: fading/gone
                    if (step == 0) {
                      return _GridCell(letter: letters[idx]);
                    }
                    if (step == 1) {
                      return _GridCell(
                        letter: letters[idx],
                        highlighted: isTargeted,
                      );
                    }
                    if (step == 2) {
                      return isTargeted
                          ? _GridCell(letter: letters[idx], fading: true)
                          : _GridCell(letter: letters[idx]);
                    }
                    // step 3: targeted gone, others shifted
                    if (isTargeted) {
                      return _GridCell(letter: '·', fading: false);
                    }
                    return _GridCell(letter: letters[idx]);
                  },
                ),
            ],
          ),
      ],
    );
  }
}

// ── Scene: Wheel (row + column) ────────────────────────────────

class _WheelScene extends StatelessWidget {
  const _WheelScene({required this.step, required this.progress});

  final int step;
  final double progress;

  static const int _targetRow = 1;
  static const int _targetCol = 2;

  @override
  Widget build(BuildContext context) {
    const List<String> letters = <String>[
      'K',
      'E',
      'L',
      'İ',
      'M',
      'E',
      'L',
      'E',
      'R',
      'A',
      'N',
      'A',
      'S',
      'O',
      'R',
      'U',
    ];

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        for (int row = 0; row < 4; row++)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              for (int col = 0; col < 4; col++)
                Builder(
                  builder: (BuildContext context) {
                    final int idx = row * 4 + col;
                    final bool isTarget =
                        row == _targetRow && col == _targetCol;
                    final bool inRowOrCol =
                        row == _targetRow || col == _targetCol;

                    if (step == 0) {
                      return _GridCell(letter: letters[idx]);
                    }
                    if (step == 1) {
                      return _GridCell(
                        letter: letters[idx],
                        highlighted: isTarget,
                      );
                    }
                    if (step == 2) {
                      return _GridCell(
                        letter: letters[idx],
                        highlighted: isTarget,
                        fading: inRowOrCol && !isTarget,
                      );
                    }
                    // step 3: all row+col gone
                    return _GridCell(
                      letter: inRowOrCol ? '·' : letters[idx],
                      fading: false,
                    );
                  },
                ),
            ],
          ),
      ],
    );
  }
}

// ── Scene: Lollipop (single cell) ──────────────────────────────

class _LollipopScene extends StatelessWidget {
  const _LollipopScene({required this.step, required this.progress});

  final int step;
  final double progress;

  static const int _targetIdx = 9; // row 2, col 1

  @override
  Widget build(BuildContext context) {
    const List<String> letters = <String>[
      'K',
      'E',
      'L',
      'İ',
      'M',
      'E',
      'L',
      'E',
      'R',
      'A',
      'N',
      'A',
      'S',
      'O',
      'R',
      'U',
    ];

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        for (int row = 0; row < 4; row++)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              for (int col = 0; col < 4; col++)
                Builder(
                  builder: (BuildContext context) {
                    final int idx = row * 4 + col;
                    final bool isTarget = idx == _targetIdx;

                    if (step == 0) {
                      return _GridCell(letter: letters[idx]);
                    }
                    if (step == 1) {
                      return _GridCell(
                        letter: letters[idx],
                        highlighted: isTarget,
                      );
                    }
                    if (step == 2) {
                      return _GridCell(letter: letters[idx], fading: isTarget);
                    }
                    return _GridCell(letter: isTarget ? '·' : letters[idx]);
                  },
                ),
            ],
          ),
      ],
    );
  }
}

// ── Scene: Free Swap ───────────────────────────────────────────

class _FreeSwapScene extends StatelessWidget {
  const _FreeSwapScene({required this.step, required this.progress});

  final int step;
  final double progress;

  @override
  Widget build(BuildContext context) {
    // 3x3 grid for clarity
    const List<String> base = <String>[
      'K',
      'E',
      'L',
      'M',
      'A',
      'R',
      'S',
      'O',
      'N',
    ];
    // step 3: A(idx4) and R(idx5) are swapped
    final List<String> swapped = List<String>.from(base);
    swapped[4] = base[5]; // R → pos4
    swapped[5] = base[4]; // A → pos5

    final bool showSwapped = step == 3;
    final List<String> letters = showSwapped ? swapped : base;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        for (int row = 0; row < 3; row++)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              for (int col = 0; col < 3; col++)
                Builder(
                  builder: (BuildContext context) {
                    final int idx = row * 3 + col;
                    final bool isFirst = idx == 4;
                    final bool isSecond = idx == 5;

                    if (step == 0) {
                      return _GridCell(letter: letters[idx]);
                    }
                    if (step == 1) {
                      return _GridCell(
                        letter: letters[idx],
                        highlighted: isFirst,
                      );
                    }
                    if (step == 2) {
                      return _GridCell(
                        letter: letters[idx],
                        highlighted: isFirst || isSecond,
                      );
                    }
                    // step 3: show swapped
                    return _GridCell(
                      letter: letters[idx],
                      swapped: isFirst || isSecond,
                    );
                  },
                ),
            ],
          ),
        if (step == 3)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  Icons.swap_horiz_rounded,
                  color: Color(0xFF2E8B7A),
                  size: 18,
                ),
                SizedBox(width: 4),
                Text(
                  'Yer değiştirdi!',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2E8B7A),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ── Scene: Shuffle ─────────────────────────────────────────────

class _ShuffleScene extends StatelessWidget {
  const _ShuffleScene({required this.step, required this.progress});

  final int step;
  final double progress;

  static const List<String> _before = <String>[
    'K',
    'E',
    'L',
    'İ',
    'M',
    'A',
    'R',
    'E',
    'S',
    'O',
    'N',
    'A',
    'T',
    'U',
    'R',
    'K',
  ];

  static const List<String> _after = <String>[
    'A',
    'R',
    'E',
    'M',
    'K',
    'L',
    'İ',
    'S',
    'O',
    'N',
    'T',
    'E',
    'U',
    'K',
    'A',
    'R',
  ];

  @override
  Widget build(BuildContext context) {
    final List<String> letters = step >= 3 ? _after : _before;
    final bool allHighlighted = step == 2;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        for (int row = 0; row < 4; row++)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              for (int col = 0; col < 4; col++)
                _GridCell(
                  letter: letters[row * 4 + col],
                  highlighted: allHighlighted,
                  swapped: step == 3,
                ),
            ],
          ),
        if (step == 2 || step == 3)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  step == 2
                      ? Icons.shuffle_rounded
                      : Icons.check_circle_rounded,
                  color: step == 2
                      ? const Color(0xFF4A3B6B)
                      : const Color(0xFF2E8B7A),
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  step == 2 ? 'Karıştırılıyor...' : 'Karıştırma tamamlandı!',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: step == 2
                        ? const Color(0xFF4A3B6B)
                        : const Color(0xFF2E8B7A),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ── Scene: Party Booster ───────────────────────────────────────

class _PartyScene extends StatelessWidget {
  const _PartyScene({required this.step, required this.progress});

  final int step;
  final double progress;

  static const List<String> _before = <String>[
    'K',
    'E',
    'L',
    'İ',
    'M',
    'A',
    'R',
    'E',
    'S',
    'O',
    'N',
    'A',
    'T',
    'U',
    'R',
    'K',
  ];

  static const List<String> _after = <String>[
    'Y',
    'E',
    'N',
    'İ',
    'H',
    'A',
    'R',
    'F',
    'L',
    'E',
    'R',
    'İ',
    'Z',
    'A',
    'B',
    'C',
  ];

  @override
  Widget build(BuildContext context) {
    if (step == 0) {
      return _buildGrid(_before, allFading: false);
    }
    if (step == 1) {
      return _buildGrid(_before, allFading: false, allHighlighted: true);
    }
    if (step == 2) {
      return _buildGrid(_before, allFading: true);
    }
    // step 3: new letters
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        ..._buildGridRows(_after, allSwapped: true),
        const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                Icons.celebration_rounded,
                color: Color(0xFF7C5DA6),
                size: 16,
              ),
              SizedBox(width: 4),
              Text(
                'Yeni harfler geldi!',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF7C5DA6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGrid(
    List<String> letters, {
    bool allFading = false,
    bool allHighlighted = false,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: _buildGridRows(
        letters,
        allFading: allFading,
        allHighlighted: allHighlighted,
      ),
    );
  }

  List<Widget> _buildGridRows(
    List<String> letters, {
    bool allFading = false,
    bool allHighlighted = false,
    bool allSwapped = false,
  }) {
    return <Widget>[
      for (int row = 0; row < 4; row++)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            for (int col = 0; col < 4; col++)
              _GridCell(
                letter: letters[row * 4 + col],
                fading: allFading,
                highlighted: allHighlighted,
                swapped: allSwapped,
              ),
          ],
        ),
    ];
  }
}

// ── Gold Header Chip ───────────────────────────────────────────

class _GoldHeaderChip extends StatelessWidget {
  const _GoldHeaderChip({
    required this.goldBalance,
    required this.onDebugAddGold,
  });

  final int goldBalance;
  final Future<void> Function() onDebugAddGold;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Altın bakiyesi: $goldBalance. Uzun basinca +10K eklenir.',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const Key('market-debug-add-gold'),
          borderRadius: BorderRadius.circular(999),
          onLongPress: () {
            unawaited(onDebugAddGold());
          },
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF4E4C8),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFE1C89C)),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(
                    Icons.monetization_on_rounded,
                    color: Color(0xFF9A6B00),
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$goldBalance',
                    key: const Key('market-gold-balance'),
                    style: const TextStyle(
                      color: Color(0xFF6E5432),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Joker Card ─────────────────────────────────────────────────

class _JokerCard extends StatelessWidget {
  const _JokerCard({
    required this.joker,
    required this.quantity,
    required this.isPurchasing,
    required this.canPurchase,
    required this.onShowDetails,
    required this.onPurchase,
    required this.onShowHowItWorks,
  });

  final MarketJokerDefinition joker;
  final int quantity;
  final bool isPurchasing;
  final bool canPurchase;
  final VoidCallback onShowDetails;
  final VoidCallback onPurchase;
  final VoidCallback onShowHowItWorks;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: Key('market-joker-${joker.id}'),
      color: Colors.white.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onShowDetails,
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE4D3B8)),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // ── Header row ───────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _JokerArtwork(jokerId: joker.id),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            joker.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF2F261D),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: <Widget>[
                              _InfoChip(
                                key: Key('market-price-${joker.id}'),
                                icon: Icons.toll_rounded,
                                label: '${joker.cost}',
                              ),
                              _InfoChip(
                                key: Key('market-stock-${joker.id}'),
                                icon: Icons.inventory_2_rounded,
                                label: '$quantity',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── Özellik Açıklaması ────────────────
                Text(
                  joker.description,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: Color(0xFF3A3025),
                  ),
                ),
                const SizedBox(height: 10),

                // ── Kullanım Amacı ────────────────────
                _DetailBlock(title: 'Kullanım amacı', content: joker.purpose),
                const SizedBox(height: 14),

                // ── Nasıl çalışır butonu ──────────────
                GestureDetector(
                  onTap: onShowHowItWorks,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A3B6B).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF4A3B6B).withValues(alpha: 0.18),
                      ),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(
                            Icons.play_circle_outline_rounded,
                            size: 16,
                            color: Color(0xFF4A3B6B),
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Nasıl Kullanılır?',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF4A3B6B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // ── Satın Al butonu ───────────────────
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    key: Key('market-buy-${joker.id}'),
                    onPressed: canPurchase && !isPurchasing ? onPurchase : null,
                    icon: isPurchasing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.shopping_cart_checkout_rounded),
                    label: Text(isPurchasing ? 'İşleniyor' : 'Satın Al'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Joker Artwork ──────────────────────────────────────────────

class _JokerArtwork extends StatelessWidget {
  const _JokerArtwork({required this.jokerId});

  final String jokerId;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: <Color>[Color(0xFF1A5D57), Color(0xFF2E8B7A)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: JokerArtImage(jokerId: jokerId, size: 48, circular: true),
      ),
    );
  }
}

// ── Detail Block ───────────────────────────────────────────────

class _DetailBlock extends StatelessWidget {
  const _DetailBlock({required this.title, required this.content});

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Color(0xFF7A6F62),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          content,
          style: const TextStyle(
            fontSize: 14,
            height: 1.45,
            color: Color(0xFF3A3025),
          ),
        ),
      ],
    );
  }
}

// ── Info Chip ──────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  const _InfoChip({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF6EEE1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 14, color: const Color(0xFF8B6A12)),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF604A12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
