import 'package:flutter/material.dart';

import 'package:crush_word/src/core/models/game_result.dart';
import 'package:crush_word/src/features/score_history/history_controller.dart';

/// Displays aggregate summary metrics and a newest-first list
/// of saved game history cards.
class ScoreHistoryScreen extends StatefulWidget {
  const ScoreHistoryScreen({super.key, required this.controller});

  final HistoryController controller;

  @override
  State<ScoreHistoryScreen> createState() => _ScoreHistoryScreenState();
}

class _ScoreHistoryScreenState extends State<ScoreHistoryScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onStateChanged);
    widget.controller.load();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final HistoryState state = widget.controller.state;

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
        child: SizedBox.expand(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : _HistoryBody(state: state),
        ),
      ),
    );
  }
}

class _HistoryBody extends StatelessWidget {
  const _HistoryBody({required this.state});

  final HistoryState state;

  @override
  Widget build(BuildContext context) {
    if (state.results.isEmpty) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.emoji_events_rounded,
                size: 48,
                color: Color(0xFF7C5DA6),
              ),
              SizedBox(height: 16),
              Text(
                'Henüz kayıtlı oyun yok',
                key: Key('history-empty'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF3A3025),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Bir oyun tamamladığında sonuçların '
                'burada görünecek.',
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
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: state.results.length + 1,
      itemBuilder: (BuildContext context, int index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _SummarySection(
              key: const Key('history-summary'),
              summary: state.summary,
            ),
          );
        }

        final GameResult result = state.results[index - 1];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _HistoryCard(
            key: Key('history-card-${result.id}'),
            result: result,
            gameNumber: state.results.length - (index - 1),
          ),
        );
      },
    );
  }
}

// ── Summary section ──────────────────────────────────────────

class _SummarySection extends StatelessWidget {
  const _SummarySection({super.key, required this.summary});

  final HistorySummary summary;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF4A3B6B), Color(0xFF7C5DA6)],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF4A3B6B).withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Row(
              children: <Widget>[
                Icon(
                  Icons.emoji_events_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                SizedBox(width: 8),
                Text(
                  'Genel İstatistikler',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: <Widget>[
                _SummaryTile(
                  key: const Key('summary-total-games'),
                  label: 'Toplam Oyun',
                  value: '${summary.totalGames}',
                  icon: Icons.sports_esports_rounded,
                ),
                _SummaryTile(
                  key: const Key('summary-high-score'),
                  label: 'En Yüksek Skor',
                  value: '${summary.highScore}',
                  icon: Icons.star_rounded,
                ),
                _SummaryTile(
                  key: const Key('summary-avg-score'),
                  label: 'Ortalama Skor',
                  value: '${summary.averageScore}',
                  icon: Icons.trending_up_rounded,
                ),
                _SummaryTile(
                  key: const Key('summary-total-words'),
                  label: 'Toplam Kelime',
                  value: '${summary.totalWords}',
                  icon: Icons.abc_rounded,
                ),
                _SummaryTile(
                  key: const Key('summary-longest-word'),
                  label: 'En Uzun Kelime',
                  value: summary.longestWord.isEmpty
                      ? '-'
                      : summary.longestWord,
                  icon: Icons.text_fields_rounded,
                ),
                _SummaryTile(
                  key: const Key('summary-total-duration'),
                  label: 'Toplam Süre',
                  value: _formatDuration(summary.totalDuration),
                  icon: Icons.timer_rounded,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          child: Row(
            children: <Widget>[
              Icon(icon, color: Colors.white70, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      value,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      label,
                      style: TextStyle(
                        color: Colors.white.withValues(
                          alpha: 0.65,
                        ),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── History card ──────────────────────────────────────────────

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    super.key,
    required this.result,
    required this.gameNumber,
  });

  final GameResult result;
  final int gameNumber;

  @override
  Widget build(BuildContext context) {
    final String dateText = _formatDate(result.completedAt);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF4A3B6B).withValues(alpha: 0.08),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // ── Header row ───────────────────────
            Row(
              children: <Widget>[
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: <Color>[
                        Color(0xFF4A3B6B),
                        Color(0xFF7C5DA6),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    child: Text(
                      '#$gameNumber',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    dateText,
                    key: const Key('history-card-date'),
                    style: const TextStyle(
                      color: Color(0xFF7A6F62),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${result.score}',
                  key: const Key('history-card-score'),
                  style: const TextStyle(
                    color: Color(0xFF3A3025),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Detail chips ─────────────────────
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                _DetailChip(
                  key: const Key('history-card-grid'),
                  icon: Icons.grid_4x4_rounded,
                  label: result.config.gridLabel,
                ),
                _DetailChip(
                  key: const Key('history-card-moves'),
                  icon: Icons.swap_vert_rounded,
                  label: '${result.config.moveLimit} hamle',
                ),
                _DetailChip(
                  key: const Key('history-card-words'),
                  icon: Icons.abc_rounded,
                  label: '${result.wordsFoundCount} kelime',
                ),
                _DetailChip(
                  key: const Key('history-card-longest'),
                  icon: Icons.text_fields_rounded,
                  label: result.longestWord.isEmpty
                      ? '-'
                      : result.longestWord,
                ),
                _DetailChip(
                  key: const Key('history-card-duration'),
                  icon: Icons.timer_rounded,
                  label: _formatDuration(result.duration),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({
    super.key,
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF5EBDA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 6,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              icon,
              size: 14,
              color: const Color(0xFF7A6F62),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF5A5245),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────

String _formatDuration(Duration duration) {
  final int hours = duration.inHours;
  final int minutes = duration.inMinutes.remainder(60);
  final int seconds = duration.inSeconds.remainder(60);

  if (hours > 0) {
    return '${hours}sa ${minutes}dk';
  }
  if (minutes > 0) {
    return '${minutes}dk ${seconds}sn';
  }
  return '${seconds}sn';
}

String _formatDate(DateTime dt) {
  final String day = dt.day.toString().padLeft(2, '0');
  final String month = dt.month.toString().padLeft(2, '0');
  final int year = dt.year;
  final String hour = dt.hour.toString().padLeft(2, '0');
  final String minute = dt.minute.toString().padLeft(2, '0');
  return '$day.$month.$year  $hour:$minute';
}
