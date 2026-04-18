import 'package:flutter/material.dart';

import 'package:crush_word/src/core/models/app_user.dart';
import 'package:crush_word/src/core/repositories/profile_repository.dart';
import 'package:crush_word/src/features/home/home_menu_destinations.dart';
import 'package:crush_word/src/features/onboarding/username_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.initialUser,
    required this.profileRepository,
  });

  final AppUser initialUser;
  final ProfileRepository profileRepository;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AppUser _user;
  bool _isSavingUsername = false;
  late final AnimationController _staggerController;

  @override
  void initState() {
    super.initState();
    _user = widget.initialUser;
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  Future<void> _editUsername() async {
    final String? updatedUsername = await showUsernameDialog(
      context: context,
      initialUsername: _user.username,
      title: 'Kullanıcı adını güncelle',
      confirmLabel: 'Güncelle',
    );

    if (!mounted || updatedUsername == null) {
      return;
    }

    setState(() {
      _isSavingUsername = true;
    });

    final AppUser updatedUser = await widget.profileRepository.saveUsername(
      updatedUsername,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _user = updatedUser;
      _isSavingUsername = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
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
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 16,
            ),
            child: Column(
              children: <Widget>[
                // ── Username button ──────────────────────
                Align(
                  alignment: Alignment.topLeft,
                  child: _FadeSlideIn(
                    animation: _staggerController,
                    intervalStart: 0,
                    intervalEnd: 0.3,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: Colors.white.withValues(alpha: 0.7),
                        border: Border.all(
                          color: theme.colorScheme.primary
                              .withValues(alpha: 0.08),
                        ),
                      ),
                      child: InkWell(
                        key: const Key('home-username-button'),
                        borderRadius: BorderRadius.circular(999),
                        onTap:
                            _isSavingUsername ? null : _editUsername,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              if (_isSavingUsername)
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                )
                              else
                                Icon(
                                  Icons.person_rounded,
                                  size: 16,
                                  color:
                                      theme.colorScheme.primary,
                                ),
                              const SizedBox(width: 6),
                              Text(
                                _user.username,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color:
                                      theme.colorScheme.primary,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.edit_rounded,
                                size: 12,
                                color: theme
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.5),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Scrollable content ──────────────────
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: <Widget>[
                        const SizedBox(height: 24),

                        // ── Hero image ──────────────────
                        _FadeSlideIn(
                          animation: _staggerController,
                          intervalStart: 0.1,
                          intervalEnd: 0.5,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: 180,
                              maxHeight: 180,
                            ),
                            child: Image.asset(
                              'assets/images/word_crush_hero.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ── Title ───────────────────────
                        _FadeSlideIn(
                          animation: _staggerController,
                          intervalStart: 0.2,
                          intervalEnd: 0.55,
                          child: ShaderMask(
                            shaderCallback: (Rect bounds) {
                              return const LinearGradient(
                                colors: <Color>[
                                  Color(0xFF1A5D57),
                                  Color(0xFF2E8B7A),
                                  Color(0xFF1A5D57),
                                ],
                              ).createShader(bounds);
                            },
                            child: Text(
                              'Word Crush',
                              style: theme.textTheme.displaySmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _FadeSlideIn(
                          animation: _staggerController,
                          intervalStart: 0.25,
                          intervalEnd: 0.6,
                          child: Text(
                            'Harfleri birleştir, kelimeleri keşfet!',
                            style: theme.textTheme.bodyLarge
                                ?.copyWith(
                                  color: const Color(0xFF5A5245),
                                  height: 1.4,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // ── Menu cards ──────────────────
                        for (int i = 0;
                            i < primaryDestinations.length;
                            i++) ...<Widget>[
                          _FadeSlideIn(
                            animation: _staggerController,
                            intervalStart: 0.35 + (i * 0.12),
                            intervalEnd: 0.65 + (i * 0.12),
                            child: _MenuCard(
                              destination:
                                  primaryDestinations[i],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        const SizedBox(height: 24),
                      ],
                    ),
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

class _MenuCard extends StatefulWidget {
  const _MenuCard({required this.destination});

  final AppDestination destination;

  @override
  State<_MenuCard> createState() => _MenuCardState();
}

class _MenuCardState extends State<_MenuCard> {
  bool _pressed = false;

  static const Map<String, List<Color>> _gradients =
      <String, List<Color>>{
    'newGame': <Color>[Color(0xFF1A5D57), Color(0xFF2E8B7A)],
    'scoreHistory': <Color>[Color(0xFF4A3B6B), Color(0xFF7C5DA6)],
    'market': <Color>[Color(0xFFB8860B), Color(0xFFD4A017)],
  };

  List<Color> get _colors {
    final String name = widget.destination.routeName
        .replaceFirst('/', '')
        .replaceAllMapped(
          RegExp(r'[-_](\w)'),
          (Match m) => m.group(1)!.toUpperCase(),
        );
    return _gradients[name] ??
        const <Color>[Color(0xFF1A5D57), Color(0xFF2E8B7A)];
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        Navigator.of(
          context,
        ).pushNamed(widget.destination.routeName);
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
              colors: _colors,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: _colors.first.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
            child: Row(
              children: <Widget>[
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Icon(
                      widget.destination.icon,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        widget.destination.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.destination.description,
                        style: TextStyle(
                          color: Colors.white
                              .withValues(alpha: 0.75),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
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

/// Staggered fade + slide-up entrance animation.
class _FadeSlideIn extends StatelessWidget {
  const _FadeSlideIn({
    required this.animation,
    required this.intervalStart,
    required this.intervalEnd,
    required this.child,
  });

  final Animation<double> animation;
  final double intervalStart;
  final double intervalEnd;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget? child) {
        final double t = Curves.easeOutCubic.transform(
          Interval(
            intervalStart.clamp(0, 1),
            intervalEnd.clamp(0, 1),
          ).transform(animation.value),
        );
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - t)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
