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

class _HomeScreenState extends State<HomeScreen> {
  late AppUser _user;
  bool _isSavingUsername = false;

  @override
  void initState() {
    super.initState();
    _user = widget.initialUser;
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: OutlinedButton.icon(
                  key: const Key('home-username-button'),
                  onPressed: _isSavingUsername ? null : _editUsername,
                  icon: _isSavingUsername
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.edit_rounded),
                  label: Text(_user.username),
                ),
              ),
              const Spacer(),
              Text(
                'Word Crush',
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Kelime hamleni seç, oturumunu planla ve bir sonraki fazlara hazır hedeflerden ilerle.',
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              for (final AppDestination destination in primaryDestinations) ...[
                _MenuActionButton(destination: destination),
                const SizedBox(height: 14),
              ],
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuActionButton extends StatelessWidget {
  const _MenuActionButton({required this.destination});

  final AppDestination destination;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      key: Key('menu-${destination.routeName}'),
      onPressed: () {
        Navigator.of(context).pushNamed(destination.routeName);
      },
      icon: Icon(destination.icon),
      label: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(destination.label),
            const SizedBox(height: 4),
            Text(
              destination.description,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
