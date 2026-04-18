import 'package:flutter/material.dart';

import 'package:crush_word/src/app/app_routes.dart';
import 'package:crush_word/src/core/models/app_user.dart';
import 'package:crush_word/src/core/repositories/profile_repository.dart';
import 'package:crush_word/src/features/onboarding/username_dialog.dart';

class UsernameGate extends StatefulWidget {
  const UsernameGate({super.key, required this.profileRepository});

  final ProfileRepository profileRepository;

  @override
  State<UsernameGate> createState() => _UsernameGateState();
}

class _UsernameGateState extends State<UsernameGate> {
  bool _isLoading = true;
  bool _dialogOpen = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final AppUser? user = await widget.profileRepository.loadUser();

    if (!mounted) {
      return;
    }

    if (user != null) {
      _goToHome(user);
      return;
    }

    setState(() {
      _isLoading = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _openFirstLaunchDialog();
      }
    });
  }

  Future<void> _openFirstLaunchDialog() async {
    if (_dialogOpen) {
      return;
    }

    _dialogOpen = true;
    final String? username = await showUsernameDialog(
      context: context,
      title: 'Word Crush\'a hoş geldin',
      confirmLabel: 'Başla',
      allowCancel: false,
    );
    _dialogOpen = false;

    if (!mounted || username == null) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final AppUser savedUser = await widget.profileRepository.saveUsername(
        username,
      );

      if (!mounted) {
        return;
      }

      _goToHome(savedUser);
    } on ArgumentError {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = 'Kullanıcı adı kaydedilemedi. Lütfen tekrar dene.';
      });
    }
  }

  void _goToHome(AppUser user) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      Navigator.of(
        context,
      ).pushReplacementNamed(AppRoutes.home, arguments: user);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.primaryContainer.withValues(alpha: 0.55),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.74),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Word Crush',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'Kelime zincirini kurmadan önce oyuncu adını sabitle.',
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _errorMessage ??
                      'İlk açılışta bir kullanıcı adı alıyoruz; sonraki girişlerde seni doğrudan ana ekrana taşıyoruz.',
                  style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isLoading ? null : _openFirstLaunchDialog,
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Kullanıcı Adını Gir'),
                ),
                const SizedBox(height: 12),
                Text(
                  'Hazır hedefler: Yeni Oyun, Skor Tablosu, Market',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
