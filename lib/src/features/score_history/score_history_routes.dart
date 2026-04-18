import 'package:flutter/material.dart';

class ScoreHistoryRoutes {
  static Route<dynamic> build(RouteSettings settings) {
    return MaterialPageRoute<void>(
      builder: (_) => const _ScoreHistoryScreenPlaceholder(),
      settings: settings,
    );
  }
}

class _ScoreHistoryScreenPlaceholder extends StatelessWidget {
  const _ScoreHistoryScreenPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: const Color(0xFF3A3025),
        elevation: 0,
        title: const Text(
          'Skor Tablosu',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF3A3025),
          ),
        ),
      ),
      extendBodyBehindAppBar: false,
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
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: <Color>[Color(0xFF4A3B6B), Color(0xFF7C5DA6)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(20),
                    child: Icon(
                      Icons.emoji_events_rounded,
                      size: 44,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Çok Yakında',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF3A3025),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Skor geçmişin burada listelenecek.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF7A6F62),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
