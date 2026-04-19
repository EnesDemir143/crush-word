import 'package:flutter/foundation.dart';

import 'package:crush_word/src/core/models/game_result.dart';
import 'package:crush_word/src/core/repositories/game_history_repository.dart';

/// Aggregate summary metrics derived from saved game results.
class HistorySummary {
  const HistorySummary({
    required this.totalGames,
    required this.highScore,
    required this.averageScore,
    required this.totalWords,
    required this.longestWord,
    required this.totalDuration,
  });

  static const HistorySummary empty = HistorySummary(
    totalGames: 0,
    highScore: 0,
    averageScore: 0,
    totalWords: 0,
    longestWord: '',
    totalDuration: Duration.zero,
  );

  final int totalGames;
  final int highScore;
  final int averageScore;
  final int totalWords;
  final String longestWord;
  final Duration totalDuration;
}

/// View-model exposed by [HistoryController].
class HistoryState {
  const HistoryState({
    required this.summary,
    required this.results,
    required this.isLoading,
  });

  static const HistoryState initial = HistoryState(
    summary: HistorySummary.empty,
    results: <GameResult>[],
    isLoading: true,
  );

  final HistorySummary summary;
  final List<GameResult> results;
  final bool isLoading;
}

/// Reads saved game results from [GameHistoryRepository] and
/// derives the six required aggregate summary metrics.
class HistoryController extends ChangeNotifier {
  HistoryController({required GameHistoryRepository repository})
    : _repository = repository;

  final GameHistoryRepository _repository;

  HistoryState _state = HistoryState.initial;
  HistoryState get state => _state;

  /// Loads results newest-first and computes aggregate metrics.
  Future<void> load() async {
    final List<GameResult> results =
        await _repository.loadResultsNewestFirst();

    final HistorySummary summary = _deriveSummary(results);

    _state = HistoryState(
      summary: summary,
      results: results,
      isLoading: false,
    );
    notifyListeners();
  }

  HistorySummary _deriveSummary(List<GameResult> results) {
    if (results.isEmpty) {
      return HistorySummary.empty;
    }

    int highScore = 0;
    int totalScore = 0;
    int totalWords = 0;
    String longestWord = '';
    Duration totalDuration = Duration.zero;

    for (final GameResult result in results) {
      if (result.score > highScore) {
        highScore = result.score;
      }
      totalScore += result.score;
      totalWords += result.wordsFoundCount;
      if (result.longestWord.length > longestWord.length) {
        longestWord = result.longestWord;
      }
      totalDuration += result.duration;
    }

    return HistorySummary(
      totalGames: results.length,
      highScore: highScore,
      averageScore: totalScore ~/ results.length,
      totalWords: totalWords,
      longestWord: longestWord,
      totalDuration: totalDuration,
    );
  }
}
