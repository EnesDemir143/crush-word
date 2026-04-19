import 'package:flutter/material.dart';

import 'package:crush_word/src/core/repositories/game_history_repository.dart';
import 'package:crush_word/src/features/score_history/history_controller.dart';
import 'package:crush_word/src/features/score_history/score_history_screen.dart';

class ScoreHistoryRoutes {
  static Route<dynamic> build(RouteSettings settings) {
    return MaterialPageRoute<void>(
      builder: (_) {
        final GameHistoryRepository repository =
            GameHistoryRepository();
        final HistoryController controller =
            HistoryController(repository: repository);
        return ScoreHistoryScreen(controller: controller);
      },
      settings: settings,
    );
  }
}
