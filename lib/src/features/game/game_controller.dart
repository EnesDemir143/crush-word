import 'package:flutter/foundation.dart';

import 'package:crush_word/src/core/config/game_rules_config.dart';
import 'package:crush_word/src/core/config/game_rules_loader.dart';
import 'package:crush_word/src/core/gameplay/models/board_cell.dart';
import 'package:crush_word/src/core/gameplay/models/game_session.dart';
import 'package:crush_word/src/core/gameplay/services/board_analyzer.dart';
import 'package:crush_word/src/core/gameplay/services/board_generator.dart';
import 'package:crush_word/src/core/gameplay/services/board_recovery.dart';
import 'package:crush_word/src/core/gameplay/services/word_validator.dart';
import 'package:crush_word/src/core/models/game_config.dart';
import 'package:crush_word/src/core/repositories/dictionary_repository.dart';

/// Lightweight feedback state shown after an invalid attempt.
///
/// This is a transient value that lives for one UI frame cycle and
/// is consumed (cleared) by the next user interaction.  No dialog or
/// popup is used.
class InvalidAttemptFeedback {
  const InvalidAttemptFeedback({required this.reason, required this.word});

  final WordValidationReason reason;
  final String word;
}

class GameController extends ChangeNotifier {
  GameController({
    required GameConfig config,
    GameRulesLoader? rulesLoader,
    BoardGenerator? boardGenerator,
    DictionaryRepository? dictionaryRepository,
    BoardAnalyzer? boardAnalyzer,
    WordValidator? wordValidator,
    GameSession? initialSession,
  }) : _config = config,
       _rulesLoader = rulesLoader ?? const GameRulesLoader(),
       _boardGenerator = boardGenerator ?? BoardGenerator(),
       _dictionaryRepository = dictionaryRepository ?? DictionaryRepository(),
       _boardAnalyzer = boardAnalyzer ?? BoardAnalyzer(),
       _wordValidator = wordValidator,
       _session = initialSession;

  factory GameController.fromSession(
    GameSession session, {
    GameRulesLoader? rulesLoader,
    BoardGenerator? boardGenerator,
    DictionaryRepository? dictionaryRepository,
    BoardAnalyzer? boardAnalyzer,
    WordValidator? wordValidator,
  }) {
    return GameController(
      config: session.config,
      rulesLoader: rulesLoader,
      boardGenerator: boardGenerator,
      dictionaryRepository: dictionaryRepository,
      boardAnalyzer: boardAnalyzer,
      wordValidator: wordValidator,
      initialSession: session,
    );
  }

  final GameConfig _config;
  final GameRulesLoader _rulesLoader;
  final BoardGenerator _boardGenerator;
  final DictionaryRepository _dictionaryRepository;
  final BoardAnalyzer _boardAnalyzer;

  /// Lazily initialised word validator — uses the injected instance or
  /// creates one from the dictionary repository.
  WordValidator? _wordValidator;
  WordValidator get _validator =>
      _wordValidator ??= WordValidator(
        dictionaryRepository: _dictionaryRepository,
      );

  GameSession? _session;
  bool _isLoading = false;
  String? _errorMessage;

  /// Transient feedback shown when the last attempt was invalid.
  /// Cleared automatically on the next [startSelection] or [endSelection].
  InvalidAttemptFeedback? _lastInvalidFeedback;

  /// Whether a finalization is already running (prevents double-taps).
  bool _isFinalizing = false;

  GameConfig get config => _config;
  GameSession? get session => _session;
  bool get hasSession => _session != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  InvalidAttemptFeedback? get lastInvalidFeedback => _lastInvalidFeedback;
  bool get isFinalizing => _isFinalizing;

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

  String get selectedWord =>
      selectedCells.map((BoardCell cell) => cell.letter).join();

  Future<void> load({bool force = false}) async {
    if (_session != null && !force) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final GameRulesConfig rules = await _rulesLoader.load();
      final Set<String> dictionary = await _dictionaryRepository.loadWords();

      GameSession session = _boardGenerator.createSession(
        config: _config,
        rules: rules,
      );

      // Initial-board solvability gate: guarantee at least one
      // valid word before the player ever sees the board.
      final BoardRecovery recovery = BoardRecovery(
        analyzer: _boardAnalyzer,
        boardGenerator: _boardGenerator,
      );

      _session = recovery.ensurePlayable(
        session: session,
        dictionary: dictionary,
        rules: rules,
      );
    } catch (_) {
      _errorMessage =
          'Oyun tahtası kurulamadı. '
          'Kurallar dosyası tekrar yüklenmeli.';
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

    // Clear any previous invalid feedback when the user starts a new attempt.
    _lastInvalidFeedback = null;

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

  /// Called when the user lifts their finger.  Finalizes the active
  /// selection into a word candidate, validates it, consumes one move
  /// and either keeps the board (invalid) or marks it valid for
  /// downstream scoring/refill (Phase 03-02).
  Future<void> endSelection() async {
    final GameSession? activeSession = _session;

    if (activeSession == null) {
      return;
    }

    // Nothing to finalize when no cells were selected.
    if (activeSession.selectedCellIds.isEmpty) {
      return;
    }

    // Guard against concurrent finalization.
    if (_isFinalizing) {
      return;
    }

    _isFinalizing = true;

    try {
      // Build the word from the selected letters.
      final List<String> letters = activeSession.selectedCellIds
          .map((String cellId) => _cellById(activeSession, cellId).letter)
          .toList(growable: false);

      final WordValidationResult result = await _validator.validate(letters);

      // Both valid and invalid attempts consume one move (GRID-06).
      final int newMovesLeft = (activeSession.movesLeft - 1).clamp(0, 999);

      if (result.isValid) {
        // Valid word: clear selection and update moves.
        // Scoring, gravity and refill will be added in 03-02.
        _session = activeSession.copyWith(
          selectedCellIds: const <String>[],
          movesLeft: newMovesLeft,
        );
        _lastInvalidFeedback = null;
      } else {
        // Invalid word: revert selection, consume the move, show feedback.
        _session = activeSession.copyWith(
          selectedCellIds: const <String>[],
          movesLeft: newMovesLeft,
        );
        _lastInvalidFeedback = InvalidAttemptFeedback(
          reason: result.reason,
          word: result.word,
        );
      }

      notifyListeners();
    } catch (error) {
      // On unexpected error (e.g. dictionary load failure), still
      // consume the move and clear selection so the UI doesn't freeze.
      debugPrint('endSelection error: $error');
      final int newMovesLeft = (activeSession.movesLeft - 1).clamp(0, 999);
      _session = activeSession.copyWith(
        selectedCellIds: const <String>[],
        movesLeft: newMovesLeft,
      );
      _lastInvalidFeedback = InvalidAttemptFeedback(
        reason: WordValidationReason.notInDictionary,
        word: activeSession.selectedCellIds
            .map((String cellId) => _cellById(activeSession, cellId).letter)
            .join()
            .toLowerCase(),
      );
      notifyListeners();
    } finally {
      _isFinalizing = false;
    }
  }

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
