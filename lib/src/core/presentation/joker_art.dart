import 'package:flutter/material.dart';

import 'package:crush_word/src/core/gameplay/services/joker_engine.dart';

String jokerAssetPath(String jokerId) => 'assets/images/jokers/$jokerId.png';

class JokerArtImage extends StatelessWidget {
  const JokerArtImage({
    super.key,
    required this.jokerId,
    required this.size,
    this.opacity = 1,
    this.circular = false,
  });

  final String jokerId;
  final double size;
  final double opacity;
  final bool circular;

  @override
  Widget build(BuildContext context) {
    final Widget image = SizedBox.square(
      dimension: size,
      child: Image.asset(
        jokerAssetPath(jokerId),
        width: size,
        height: size,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
        errorBuilder: (BuildContext context, Object error, StackTrace? stack) {
          return DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0x22000000),
              shape: circular ? BoxShape.circle : BoxShape.rectangle,
              borderRadius: circular ? null : BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(
                _fallbackIconFor(jokerId),
                size: size * 0.58,
                color: Colors.white,
              ),
            ),
          );
        },
      ),
    );

    final Widget shapedImage = circular ? ClipOval(child: image) : image;

    if (opacity >= 0.999) {
      return shapedImage;
    }

    return Opacity(opacity: opacity.clamp(0, 1), child: shapedImage);
  }

  IconData _fallbackIconFor(String jokerId) {
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
