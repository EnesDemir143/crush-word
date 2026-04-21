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
    final List<MarketJokerDefinition> ownedJokers = jokers
        .where(
          (MarketJokerDefinition joker) => (inventoryById[joker.id] ?? 0) > 0,
        )
        .toList(growable: false);

    if (ownedJokers.isEmpty) {
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
                children: ownedJokers
                    .map(
                      (MarketJokerDefinition joker) => Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: _JokerChip(
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

class _JokerChip extends StatelessWidget {
  const _JokerChip({
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('joker-bar-${joker.id}'),
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 116,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isActive
                  ? const <Color>[Color(0xFF1D6D67), Color(0xFF0F4E4A)]
                  : const <Color>[Color(0xFFFFFCF6), Color(0xFFF4E8D5)],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isActive
                  ? const Color(0xFFFFE7B0)
                  : const Color(0xFFE5D4BA),
              width: isActive ? 2 : 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(
                _iconFor(joker.id),
                color: isActive ? Colors.white : const Color(0xFF7A4E15),
              ),
              const SizedBox(height: 10),
              Text(
                joker.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                  color: isActive ? Colors.white : const Color(0xFF3A3025),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Adet: $quantity',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isActive
                      ? Colors.white.withValues(alpha: 0.92)
                      : const Color(0xFF6F6355),
                ),
              ),
            ],
          ),
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
