import 'package:flutter/foundation.dart';

import 'package:crush_word/src/core/config/game_rules_loader.dart';
import 'package:crush_word/src/core/gameplay/models/board_cell.dart';
import 'package:crush_word/src/core/gameplay/models/game_session.dart';
import 'package:crush_word/src/core/gameplay/services/board_generator.dart';
import 'package:crush_word/src/core/models/game_config.dart';

class GameController extends ChangeNotifier {
  GameController({
    required GameConfig config,
    GameRulesLoader? rulesLoader,
    BoardGenerator? boardGenerator,
    GameSession? initialSession,
  }) : _config = config,
       _rulesLoader = rulesLoader ?? const GameRulesLoader(),
       _boardGenerator = boardGenerator ?? BoardGenerator(),
       _session = initialSession;

  factory GameController.fromSession(
    GameSession session, {
    GameRulesLoader? rulesLoader,
    BoardGenerator? boardGenerator,
  }) {
    return GameController(
      config: session.config,
      rulesLoader: rulesLoader,
      boardGenerator: boardGenerator,
      initialSession: session,
    );
  }

  final GameConfig _config;
  final GameRulesLoader _rulesLoader;
  final BoardGenerator _boardGenerator;

  GameSession? _session;
  bool _isLoading = false;
  String? _errorMessage;

  GameConfig get config => _config;
  GameSession? get session => _session;
  bool get hasSession => _session != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get score => _session?.score ?? 0;
  int get movesLeft => _session?.movesLeft ?? _config.moveLimit;

  List<String> get selectedCellIds =>
      _session?.selectedCellIds ?? const <String>[];

  List<BoardCell> get selectedCells {
    final GameSession? activeSession = _session;

    if (activeSession == null) {
      return const <BoardCell>[];
    }

    return activeSession.selectedCellIds
        .map((String cellId) => _cellById(activeSession, cellId))
        .toList(growable: false);
  }

  String get selectedWord => selectedCells
      .map((BoardCell cell) => cell.letter)
      .join();

  Future<void> load({bool force = false}) async {
    if (_session != null && !force) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final rules = await _rulesLoader.load();
      _session = _boardGenerator.createSession(config: _config, rules: rules);
    } catch (_) {
      _errorMessage =
          'Oyun tahtası kurulamadı. Kurallar dosyası tekrar yüklenmeli.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void startSelection(BoardCell cell) {
    final GameSession? activeSession = _session;

    if (activeSession == null) {
      return;
    }

    _session = activeSession.copyWith(selectedCellIds: <String>[cell.id]);
    notifyListeners();
  }

  void extendSelection(BoardCell cell) {
    final GameSession? activeSession = _session;

    if (activeSession == null) {
      return;
    }

    final List<String> activePath = activeSession.selectedCellIds;

    if (activePath.isEmpty) {
      startSelection(cell);
      return;
    }

    if (activePath.contains(cell.id)) {
      return;
    }

    final BoardCell lastCell = _cellById(activeSession, activePath.last);

    if (!_isAdjacent(lastCell, cell)) {
      return;
    }

    _session = activeSession.copyWith(
      selectedCellIds: <String>[...activePath, cell.id],
    );
    notifyListeners();
  }

  void clearSelection() {
    final GameSession? activeSession = _session;

    if (activeSession == null || activeSession.selectedCellIds.isEmpty) {
      return;
    }

    _session = activeSession.copyWith(selectedCellIds: const <String>[]);
    notifyListeners();
  }

  void endSelection() {}

  BoardCell _cellById(GameSession activeSession, String cellId) {
    return activeSession.board.firstWhere(
      (BoardCell cell) => cell.id == cellId,
    );
  }

  bool _isAdjacent(BoardCell source, BoardCell target) {
    final int rowDelta = (source.row - target.row).abs();
    final int columnDelta = (source.column - target.column).abs();

    return rowDelta <= 1 &&
        columnDelta <= 1 &&
        (rowDelta != 0 || columnDelta != 0);
  }
}
