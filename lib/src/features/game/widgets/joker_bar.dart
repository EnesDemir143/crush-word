import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:crush_word/src/core/config/game_rules_config.dart';
import 'package:crush_word/src/core/presentation/joker_art.dart';

class JokerBar extends StatelessWidget {
  const JokerBar({
    super.key,
    required this.jokers,
    required this.inventoryById,
    required this.onJokerPressed,
    this.onJokerBuyRequested,
    this.activeJokerId,
    this.helperText,
    this.enabled = true,
    this.jokerButtonKeys = const <String, GlobalKey>{},
  });

  final List<MarketJokerDefinition> jokers;
  final Map<String, int> inventoryById;
  final ValueChanged<String> onJokerPressed;
  final ValueChanged<String>? onJokerBuyRequested;
  final String? activeJokerId;
  final String? helperText;
  final bool enabled;
  final Map<String, GlobalKey> jokerButtonKeys;

  @override
  Widget build(BuildContext context) {
    if (jokers.isEmpty) {
      return const SizedBox.shrink();
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFEF9F1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5D4BA)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x16000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (helperText != null) ...<Widget>[
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  helperText!,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.3,
                    color: Color(0xFF6F6355),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: jokers
                    .map(
                      (MarketJokerDefinition joker) => Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: _JokerOrb(
                          joker: joker,
                          quantity: inventoryById[joker.id] ?? 0,
                          isActive: activeJokerId == joker.id,
                          enabled: enabled,
                          buttonKey: jokerButtonKeys[joker.id],
                          onPressed: () => onJokerPressed(joker.id),
                          onBuyRequested: onJokerBuyRequested != null
                              ? () => onJokerBuyRequested!(joker.id)
                              : null,
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JokerOrb extends StatefulWidget {
  const _JokerOrb({
    required this.joker,
    required this.quantity,
    required this.isActive,
    required this.enabled,
    required this.onPressed,
    this.buttonKey,
    this.onBuyRequested,
  });

  final MarketJokerDefinition joker;
  final int quantity;
  final bool isActive;
  final bool enabled;
  final GlobalKey? buttonKey;
  final VoidCallback onPressed;
  final VoidCallback? onBuyRequested;

  @override
  State<_JokerOrb> createState() => _JokerOrbState();
}

class _JokerOrbState extends State<_JokerOrb> with TickerProviderStateMixin {
  AnimationController? _partyController;
  Animation<double>? _partyPulse;
  Animation<double>? _partySpin;
  bool _isPressed = false;

  bool get _isPartyBooster => widget.joker.id == 'party_booster';

  @override
  void initState() {
    super.initState();
    _updatePartyAnimation();
  }

  @override
  void didUpdateWidget(covariant _JokerOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.joker.id != widget.joker.id ||
        oldWidget.quantity != widget.quantity) {
      _updatePartyAnimation();
    }
  }

  @override
  void dispose() {
    _disposePartyAnimation();
    super.dispose();
  }

  void _updatePartyAnimation() {
    final bool shouldAnimate = _isPartyBooster && widget.quantity > 0;

    if (!shouldAnimate) {
      _disposePartyAnimation();
      return;
    }

    if (_partyController != null) {
      return;
    }

    final AnimationController controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _partyController = controller;
    _partyPulse = Tween<double>(
      begin: 0.92,
      end: 1.08,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
    _partySpin = CurvedAnimation(parent: controller, curve: Curves.linear);
  }

  void _disposePartyAnimation() {
    _partyController?.dispose();
    _partyController = null;
    _partyPulse = null;
    _partySpin = null;
  }

  @override
  Widget build(BuildContext context) {
    final bool isInteractive = widget.enabled;
    final bool isPartyBooster = _isPartyBooster;
    final Color accentColor = widget.isActive
        ? const Color(0xFF0F615B)
        : isPartyBooster && widget.quantity > 0
        ? const Color(0xFFB83CB8)
        : widget.quantity > 0
        ? const Color(0xFF7A4E15)
        : const Color(0xFFB7AA96);
    final bool showPressedState = isInteractive && _isPressed;

    return Material(
      color: Colors.transparent,
      child: Semantics(
        button: true,
        enabled: isInteractive,
        label: '${widget.joker.name}, x${widget.quantity}',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AnimatedScale(
              scale: showPressedState ? 0.92 : 1,
              duration: const Duration(milliseconds: 110),
              curve: Curves.easeOutCubic,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 110),
                curve: Curves.easeOutCubic,
                transform: Matrix4.translationValues(
                  0,
                  showPressedState ? 2 : 0,
                  0,
                ),
                child: InkWell(
                  key: widget.buttonKey ?? Key('joker-bar-${widget.joker.id}'),
                  onTap: isInteractive
                      ? () {
                          if (widget.quantity > 0) {
                            widget.onPressed();
                          } else if (widget.onBuyRequested != null) {
                            widget.onBuyRequested!();
                          }
                        }
                      : null,
                  onHighlightChanged: (bool highlighted) {
                    if (!isInteractive || _isPressed == highlighted) {
                      return;
                    }
                    setState(() {
                      _isPressed = highlighted;
                    });
                  },
                  borderRadius: BorderRadius.circular(999),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isPartyBooster && widget.quantity > 0
                            ? (widget.isActive
                                  ? const <Color>[
                                      Color(0xFF7B2CBF),
                                      Color(0xFF5A189A),
                                    ]
                                  : const <Color>[
                                      Color(0xFFFFF0FB),
                                      Color(0xFFFFD9F1),
                                    ])
                            : widget.isActive
                            ? const <Color>[
                                Color(0xFF1D6D67),
                                Color(0xFF0F4E4A),
                              ]
                            : widget.quantity > 0
                            ? const <Color>[
                                Color(0xFFFFFCF6),
                                Color(0xFFF4E8D5),
                              ]
                            : const <Color>[
                                Color(0xFFF2ECE2),
                                Color(0xFFE3D9CB),
                              ],
                      ),
                      border: Border.all(
                        color: isPartyBooster && widget.quantity > 0
                            ? const Color(0xFFFFD86E)
                            : widget.isActive
                            ? const Color(0xFFFFE7B0)
                            : widget.quantity > 0
                            ? const Color(0xFFE5D4BA)
                            : const Color(0xFFD5C8B7),
                        width: widget.isActive ? 2.6 : 1.4,
                      ),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: accentColor.withValues(
                            alpha: widget.isActive ? 0.24 : 0.12,
                          ),
                          blurRadius: showPressedState
                              ? (widget.isActive ? 10 : 5)
                              : (widget.isActive ? 18 : 10),
                          offset: Offset(0, showPressedState ? 2 : 6),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Stack(
                        fit: StackFit.expand,
                        children: <Widget>[
                          if (isPartyBooster &&
                              widget.quantity > 0 &&
                              _partyController != null)
                            AnimatedBuilder(
                              animation: _partyController!,
                              builder: (BuildContext context, Widget? child) {
                                final double pulse = _partyPulse?.value ?? 1;
                                final double spin = _partySpin?.value ?? 0;
                                return Stack(
                                  fit: StackFit.expand,
                                  children: <Widget>[
                                    Transform.scale(
                                      scale: pulse,
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: RadialGradient(
                                            colors: <Color>[
                                              const Color(
                                                0xFFFFE6F9,
                                              ).withValues(
                                                alpha: widget.isActive
                                                    ? 0.32
                                                    : 0.44,
                                              ),
                                              Colors.transparent,
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    Transform.rotate(
                                      angle: spin * math.pi * 2,
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: SweepGradient(
                                            colors: <Color>[
                                              Colors.transparent,
                                              const Color(
                                                0xFFFFD86E,
                                              ).withValues(alpha: 0.55),
                                              Colors.transparent,
                                              const Color(
                                                0xFFFF8AD6,
                                              ).withValues(alpha: 0.45),
                                              Colors.transparent,
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          JokerArtImage(
                            jokerId: widget.joker.id,
                            size: 72,
                            opacity: widget.quantity > 0 ? 1 : 0.48,
                            circular: true,
                          ),
                          if (widget.isActive || widget.quantity <= 0)
                            DecoratedBox(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: widget.isActive
                                    ? const Color(0x220F4E4A)
                                    : const Color(0x55F2ECE2),
                              ),
                            ),
                          if (showPressedState)
                            const DecoratedBox(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0x18000000),
                              ),
                            ),
                          if (widget.quantity <= 0)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8DCC8),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1.5,
                                  ),
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.all(3),
                                  child: Icon(
                                    Icons.add_rounded,
                                    size: 14,
                                    color: Color(0xFF7A6F62),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'x${widget.quantity}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: widget.isActive ? const Color(0xFF0F615B) : accentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
