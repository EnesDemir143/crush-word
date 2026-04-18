import 'package:flutter/foundation.dart';

import 'package:crush_word/src/core/config/game_rules_config.dart';
import 'package:crush_word/src/core/config/game_rules_loader.dart';
import 'package:crush_word/src/core/models/game_config.dart';

enum GameSetupStep { difficulty, moveCount }

class GameSetupController extends ChangeNotifier {
  GameSetupController({GameRulesLoader? loader})
    : _loader = loader ?? const GameRulesLoader();

  final GameRulesLoader _loader;

  GameRulesConfig? _rules;
  bool _isLoading = false;
  Object? _error;
  GameSetupStep _step = GameSetupStep.difficulty;
  GameSetupOption? _selectedDifficulty;

  GameRulesConfig? get rules => _rules;
  bool get isLoading => _isLoading;
  Object? get error => _error;
  GameSetupStep get step => _step;
  GameSetupOption? get selectedDifficulty => _selectedDifficulty;

  List<GameSetupOption> get difficultyOptions =>
      _rules?.setup.difficultyOptions ?? const <GameSetupOption>[];

  List<int> get availableMoveCountOptions =>
      _selectedDifficulty?.moveCountOptions ?? const <int>[];

  bool get canStepBack => _step == GameSetupStep.moveCount;

  Future<void> load({bool force = false}) async {
    if (_isLoading || (_rules != null && !force)) {
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _rules = await _loader.load();
      _step = GameSetupStep.difficulty;
      _selectedDifficulty = null;
    } catch (error) {
      _error = error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectDifficulty(GameSetupOption option) {
    _selectedDifficulty = option;
    _step = GameSetupStep.moveCount;
    notifyListeners();
  }

  void returnToDifficultySelection() {
    if (_step == GameSetupStep.difficulty) {
      return;
    }

    _step = GameSetupStep.difficulty;
    notifyListeners();
  }

  GameConfig confirmMoveCount(int moveLimit) {
    final GameSetupOption? option = _selectedDifficulty;

    if (option == null) {
      throw StateError(
        'Cannot confirm a move count before selecting a difficulty.',
      );
    }

    return option.toGameConfig(moveLimit: moveLimit);
  }
}
