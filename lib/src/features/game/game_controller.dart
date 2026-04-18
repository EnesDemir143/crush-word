import 'package:flutter/foundation.dart';

import 'package:crush_word/src/core/config/game_rules_config.dart';
import 'package:crush_word/src/core/config/game_rules_loader.dart';
import 'package:crush_word/src/core/gameplay/models/board_cell.dart';
import 'package:crush_word/src/core/gameplay/models/game_session.dart';
import 'package:crush_word/src/core/gameplay/services/board_analyzer.dart';
import 'package:crush_word/src/core/gameplay/services/board_generator.dart';
import 'package:crush_word/src/core/gameplay/services/board_recovery.dart';
import 'package:crush_word/src/core/gameplay/services/board_resolver.dart';
import 'package:crush_word/src/core/gameplay/services/scoring_engine.dart';
import 'package:crush_word/src/core/gameplay/services/word_validator.dart';
import 'package:crush_word/src/core/models/game_config.dart';
import 'package:crush_word/src/core/models/game_result.dart';
import 'package:crush_word/src/core/repositories/dictionary_repository.dart';
import 'package:crush_word/src/core/repositories/game_history_repository.dart';
import 'package:crush_word/src/core/repositories/session_checkpoint_repository.dart';

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
    ScoringEngine? scoringEngine,
    BoardResolver? boardResolver,
    GameHistoryRepository? gameHistoryRepository,
    SessionCheckpointRepository? sessionCheckpointRepository,
    DateTime Function()? clock,
    GameSession? initialSession,
  }) : _config = config,
       _rulesLoader = rulesLoader ?? const GameRulesLoader(),
       _boardGenerator = boardGenerator ?? BoardGenerator(),
       _dictionaryRepository = dictionaryRepository ?? DictionaryRepository(),
       _boardAnalyzer = boardAnalyzer ?? BoardAnalyzer(),
       _wordValidator = wordValidator,
       _scoringEngine = scoringEngine,
       _boardResolver = boardResolver,
       _gameHistoryRepository =
           gameHistoryRepository ?? GameHistoryRepository(),
       _sessionCheckpointRepository =
           sessionCheckpointRepository ?? SessionCheckpointRepository(),
       _clock = clock ?? DateTime.now,
       _session = initialSession;

  factory GameController.fromSession(
    GameSession session, {
    GameRulesLoader? rulesLoader,
    BoardGenerator? boardGenerator,
    DictionaryRepository? dictionaryRepository,
    BoardAnalyzer? boardAnalyzer,
    WordValidator? wordValidator,
    ScoringEngine? scoringEngine,
    BoardResolver? boardResolver,
    GameHistoryRepository? gameHistoryRepository,
    SessionCheckpointRepository? sessionCheckpointRepository,
    DateTime Function()? clock,
  }) {
    return GameController(
      config: session.config,
      rulesLoader: rulesLoader,
      boardGenerator: boardGenerator,
      dictionaryRepository: dictionaryRepository,
      boardAnalyzer: boardAnalyzer,
      wordValidator: wordValidator,
      scoringEngine: scoringEngine,
      boardResolver: boardResolver,
      gameHistoryRepository: gameHistoryRepository,
      sessionCheckpointRepository: sessionCheckpointRepository,
      clock: clock,
      initialSession: session,
    );
  }

  final GameConfig _config;
  final GameRulesLoader _rulesLoader;
  final BoardGenerator _boardGenerator;
  final DictionaryRepository _dictionaryRepository;
  final BoardAnalyzer _boardAnalyzer;
  final GameHistoryRepository _gameHistoryRepository;
  final SessionCheckpointRepository _sessionCheckpointRepository;
  final DateTime Function() _clock;

  /// Lazily initialised word validator — uses the injected instance or
  /// creates one from the dictionary repository.
  WordValidator? _wordValidator;
  WordValidator get _validator =>
      _wordValidator ??= WordValidator(
        dictionaryRepository: _dictionaryRepository,
      );

  /// Lazily initialised scoring engine — uses the injected instance
  /// or creates one from the loaded rules config.
  ScoringEngine? _scoringEngine;

  /// Lazily initialised board resolver.
  BoardResolver? _boardResolver;
  BoardResolver get _resolver =>
      _boardResolver ??= BoardResolver(
        boardGenerator: _boardGenerator,
      );

  /// Cached rules config set during [load] — needed for board
  /// refill letter generation.
  GameRulesConfig? _cachedRules;

  GameSession? _session;
  bool _isLoading = false;
  String? _errorMessage;

  /// Transient feedback shown when the last attempt was invalid.
  /// Cleared automatically on the next [startSelection] or [endSelection].
  InvalidAttemptFeedback? _lastInvalidFeedback;

  /// Cell IDs removed on the last valid word — used by the UI to
  /// trigger pop/gravity/refill animations.  Cleared on the next
  /// [startSelection].
  List<String> _lastRemovedCellIds = const <String>[];

  /// Score earned on the last valid word — used by the UI to
  /// display a floating "+X" animation.  Cleared on the next
  /// [startSelection].
  int _lastWordScore = 0;

  /// Whether a finalization is already running (prevents double-taps).
  bool _isFinalizing = false;

  /// Guards terminal result persistence against duplicate writes.
  String? _persistedResultId;

  GameConfig get config => _config;
  GameSession? get session => _session;
  bool get hasSession => _session != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  InvalidAttemptFeedback? get lastInvalidFeedback => _lastInvalidFeedback;
  List<String> get lastRemovedCellIds => _lastRemovedCellIds;
  int get lastWordScore => _lastWordScore;
  bool get isFinalizing => _isFinalizing;
  bool get isGameOver => movesLeft <= 0;

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
      await _persistCheckpointIfActive(_session!);
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    _persistedResultId = null;
    notifyListeners();

    try {
      final GameRulesConfig rules = await _rulesLoader.load();
      final Set<String> dictionary =
          await _dictionaryRepository.loadWords();

      // Cache rules for later use (scoring + board refill).
      _cachedRules = rules;

      // Initialise scoring engine from loaded config if not
      // injected via constructor.
      if (rules.scoring != null && _scoringEngine == null) {
        _scoringEngine = ScoringEngine(
          scoringConfig: rules.scoring!,
        );
      }

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

      await _persistCheckpointIfActive(_session!);
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

    // Clear transient state from previous attempt.
    _lastInvalidFeedback = null;
    _lastRemovedCellIds = const <String>[];
    _lastWordScore = 0;

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
      final int newMovesLeft = (activeSession.movesLeft - 1).clamp(0, 999);
      GameSession updatedSession;

      try {
        final WordValidationResult result = await _validator.validate(letters);

        if (result.isValid) {
          int wordScore = 0;
          if (_scoringEngine != null) {
            final ScoringResult scoring = _scoringEngine!.score(result.word);
            wordScore = scoring.totalScore;
          }

          List<BoardCell> newBoard = activeSession.board;
          final GameRulesConfig? rules = _cachedRules;
          if (rules != null) {
            final BoardResolveResult resolved = _resolver.resolve(
              board: activeSession.board,
              selectedCellIds: activeSession.selectedCellIds,
              gridSize: activeSession.gridSize,
              rules: rules.boardGeneration,
            );
            newBoard = resolved.board;
            _lastRemovedCellIds = activeSession.selectedCellIds;
          } else {
            _lastRemovedCellIds = const <String>[];
          }

          _lastWordScore = wordScore;
          updatedSession = activeSession.copyWith(
            board: newBoard,
            selectedCellIds: const <String>[],
            movesLeft: newMovesLeft,
            score: activeSession.score + wordScore,
            wordsFoundCount: activeSession.wordsFoundCount + 1,
            longestWord: _resolveLongestWord(
              current: activeSession.longestWord,
              candidate: result.word,
            ),
          );
          _lastInvalidFeedback = null;
        } else {
          updatedSession = activeSession.copyWith(
            selectedCellIds: const <String>[],
            movesLeft: newMovesLeft,
          );
          _lastRemovedCellIds = const <String>[];
          _lastWordScore = 0;
          _lastInvalidFeedback = InvalidAttemptFeedback(
            reason: result.reason,
            word: result.word,
          );
        }
      } catch (error) {
        // On unexpected error (e.g. dictionary load failure), still
        // consume the move and clear selection so the UI doesn't freeze.
        debugPrint('endSelection error: $error');
        updatedSession = activeSession.copyWith(
          selectedCellIds: const <String>[],
          movesLeft: newMovesLeft,
        );
        _lastRemovedCellIds = const <String>[];
        _lastWordScore = 0;
        _lastInvalidFeedback = InvalidAttemptFeedback(
          reason: WordValidationReason.notInDictionary,
          word: activeSession.selectedCellIds
              .map((String cellId) => _cellById(activeSession, cellId).letter)
              .join()
              .toLowerCase(),
        );
      }

      _session = updatedSession;
      await _syncPersistenceAfterMutation(updatedSession);
      notifyListeners();
    } finally {
      _isFinalizing = false;
    }
  }

  Future<void> confirmExit() async {
    final GameSession? activeSession = _session;
    if (activeSession == null) {
      return;
    }

    await _persistCurrentResultIfNeeded(activeSession);
    await _clearCheckpointSafely();
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

  Future<void> _syncPersistenceAfterMutation(GameSession session) async {
    if (session.movesLeft <= 0) {
      await _persistCurrentResultIfNeeded(session);
      await _clearCheckpointSafely();
      return;
    }

    await _persistCheckpointIfActive(session);
  }

  Future<void> _persistCheckpointIfActive(GameSession session) async {
    if (session.movesLeft <= 0) {
      return;
    }

    try {
      await _sessionCheckpointRepository.save(session);
    } catch (error) {
      debugPrint('checkpoint save error: $error');
    }
  }

  Future<void> _persistCurrentResultIfNeeded(GameSession session) async {
    if (_persistedResultId != null) {
      return;
    }

    final DateTime completedAt = _clock();
    final GameResult result = GameResult(
      id: 'result_${completedAt.microsecondsSinceEpoch}',
      config: session.config,
      score: session.score,
      wordsFoundCount: session.wordsFoundCount,
      longestWord: session.longestWord,
      duration: _resolveDuration(
        startedAt: session.startedAt,
        completedAt: completedAt,
      ),
      completedAt: completedAt,
    );

    await _gameHistoryRepository.saveResult(result);
    _persistedResultId = result.id;
  }

  Future<void> _clearCheckpointSafely() async {
    try {
      await _sessionCheckpointRepository.clear();
    } catch (error) {
      debugPrint('checkpoint clear error: $error');
    }
  }

  Duration _resolveDuration({
    required DateTime startedAt,
    required DateTime completedAt,
  }) {
    final Duration duration = completedAt.difference(startedAt);
    return duration.isNegative ? Duration.zero : duration;
  }

  String _resolveLongestWord({
    required String current,
    required String candidate,
  }) {
    return candidate.length > current.length ? candidate : current;
  }
}
