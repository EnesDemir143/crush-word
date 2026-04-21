import 'package:flutter/material.dart';

import 'package:crush_word/src/core/config/game_rules_config.dart';
import 'package:crush_word/src/core/gameplay/services/joker_engine.dart';

class JokerBar extends StatelessWidget {
  const JokerBar({
    super.key,
    required this.jokers,
    required this.inventoryById,
    required this.onJokerPressed,
    this.activeJokerId,
    this.helperText,
    this.enabled = true,
  });

  final List<MarketJokerDefinition> jokers;
  final Map<String, int> inventoryById;
  final ValueChanged<String> onJokerPressed;
  final String? activeJokerId;
  final String? helperText;
  final bool enabled;

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
            Row(
              children: <Widget>[
                const Icon(
                  Icons.auto_awesome_rounded,
                  color: Color(0xFF7A4E15),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Jokerler',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF3A3025),
                    ),
                  ),
                ),
                if (helperText != null)
                  Flexible(
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
              ],
            ),
            const SizedBox(height: 12),
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
                          onPressed: () => onJokerPressed(joker.id),
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

class _JokerOrb extends StatelessWidget {
  const _JokerOrb({
    required this.joker,
    required this.quantity,
    required this.isActive,
    required this.enabled,
    required this.onPressed,
  });

  final MarketJokerDefinition joker;
  final int quantity;
  final bool isActive;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final bool isAvailable = enabled && quantity > 0;
    final Color accentColor = isActive
        ? const Color(0xFF0F615B)
        : quantity > 0
        ? const Color(0xFF7A4E15)
        : const Color(0xFFB7AA96);

    return Material(
      color: Colors.transparent,
      child: Semantics(
        button: true,
        enabled: isAvailable,
        label: '${joker.name}, x$quantity',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            InkWell(
              key: Key('joker-bar-${joker.id}'),
              onTap: isAvailable ? onPressed : null,
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
                    colors: isActive
                        ? const <Color>[Color(0xFF1D6D67), Color(0xFF0F4E4A)]
                        : quantity > 0
                        ? const <Color>[Color(0xFFFFFCF6), Color(0xFFF4E8D5)]
                        : const <Color>[Color(0xFFF2ECE2), Color(0xFFE3D9CB)],
                  ),
                  border: Border.all(
                    color: isActive
                        ? const Color(0xFFFFE7B0)
                        : quantity > 0
                        ? const Color(0xFFE5D4BA)
                        : const Color(0xFFD5C8B7),
                    width: isActive ? 2.6 : 1.4,
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: accentColor.withValues(
                        alpha: isActive ? 0.24 : 0.12,
                      ),
                      blurRadius: isActive ? 18 : 10,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    _iconFor(joker.id),
                    size: 30,
                    color: isActive
                        ? Colors.white
                        : quantity > 0
                        ? const Color(0xFF7A4E15)
                        : const Color(0xFF9A8C7A),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'x$quantity',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: isActive ? const Color(0xFF0F615B) : accentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(String jokerId) {
    return switch (jokerId) {
      JokerIds.fish => Icons.set_meal_rounded,
      JokerIds.wheel => Icons.radio_button_checked_rounded,
      JokerIds.lollipopBreaker => Icons.close_rounded,
      JokerIds.freeSwap => Icons.swap_horiz_rounded,
      JokerIds.shuffleLetters => Icons.shuffle_rounded,
      JokerIds.partyBooster => Icons.celebration_rounded,
      _ => Icons.auto_awesome_rounded,
    };
  }
}
