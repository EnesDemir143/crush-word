import 'package:flutter/foundation.dart';

import 'package:crush_word/src/core/config/game_rules_config.dart';
import 'package:crush_word/src/core/config/game_rules_loader.dart';
import 'package:crush_word/src/core/gameplay/models/board_cell.dart';
import 'package:crush_word/src/core/gameplay/models/game_session.dart';
import 'package:crush_word/src/core/gameplay/services/board_analyzer.dart';
import 'package:crush_word/src/core/gameplay/services/board_generator.dart';
import 'package:crush_word/src/core/gameplay/services/board_recovery.dart';
import 'package:crush_word/src/core/gameplay/services/board_resolver.dart';
import 'package:crush_word/src/core/gameplay/services/combo_engine.dart';
import 'package:crush_word/src/core/gameplay/services/power_engine.dart';
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
  WordValidator get _validator => _wordValidator ??= WordValidator(
    dictionaryRepository: _dictionaryRepository,
  );

  /// Lazily initialised scoring engine — uses the injected instance
  /// or creates one from the loaded rules config.
  ScoringEngine? _scoringEngine;

  /// Lazily initialised board resolver.
  BoardResolver? _boardResolver;

  /// Lazily initialised power tile engine.
  PowerEngine? _powerEngine;

  /// Returns a [BoardResolver] configured with the current power
  /// tile engine (if power config is available).
  BoardResolver get _resolver {
    // Rebuild if the power engine has been initialised since the
    // last resolver was created.
    if (_boardResolver == null ||
        (_powerEngine != null && _boardResolver!.powerEngine == null)) {
      _boardResolver = BoardResolver(
        boardGenerator: _boardGenerator,
        powerEngine: _powerEngine,
      );
    }
    return _boardResolver!;
  }

  /// Lazily initialised combo detector.
  ComboDetector? _comboDetector;
  ComboDetector get _combo => _comboDetector ??= ComboDetector(
    dictionaryRepository: _dictionaryRepository,
  );

  /// Lazily initialised combo scoring engine.
  ComboScoringEngine? _comboScoringEngine;

  /// Cached rules config set during [load] — needed for board
  /// refill letter generation.
  GameRulesConfig? _cachedRules;

  /// Cached dictionary set during [load] — needed for post-move
  /// board analysis, recovery and playable word counting.
  Set<String>? _cachedDictionary;

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

  /// Number of combo hits on the last valid word (1 = main only).
  int _lastComboCount = 0;

  /// Total points earned from combo sub-words on the last valid word.
  int _lastComboBonus = 0;

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
  int get lastComboCount => _lastComboCount;
  int get lastComboBonus => _lastComboBonus;
  bool get isFinalizing => _isFinalizing;
  bool get isGameOver => movesLeft <= 0;

  int get score => _session?.score ?? 0;
  int get movesLeft => _session?.movesLeft ?? _config.moveLimit;
  int get playableWordCount => _session?.playableWordCount ?? 0;

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
    _isLoading = true;
    _errorMessage = null;
    _persistedResultId = null;
    notifyListeners();

    try {
      await _ensureRuntimeCachesLoaded();
      final GameRulesConfig rules = _cachedRules!;
      final Set<String> dictionary = _cachedDictionary!;

      if (_session != null && !force) {
        final GameSession hydratedSession = _ensurePostMovePlayability(
          _session!,
        );
        _session = hydratedSession;
        await _persistCheckpointIfActive(hydratedSession);
        return;
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

      session = recovery.ensurePlayable(
        session: session,
        dictionary: dictionary,
        rules: rules,
      );

      _session = _ensurePostMovePlayability(session);

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

  Future<void> _ensureRuntimeCachesLoaded() async {
    _cachedRules ??= await _rulesLoader.load();
    _cachedDictionary ??= await _dictionaryRepository.loadWords();

    final GameRulesConfig rules = _cachedRules!;

    if (rules.scoring != null && _scoringEngine == null) {
      _scoringEngine = ScoringEngine(scoringConfig: rules.scoring!);
    }

    if (rules.powerTiles != null && _powerEngine == null) {
      _powerEngine = PowerEngine(config: rules.powerTiles!);
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
    _lastComboCount = 0;
    _lastComboBonus = 0;

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
          int comboCount = 1;
          int comboBonus = 0;

          if (_scoringEngine != null) {
            final ScoringResult scoring = _scoringEngine!.score(result.word);
            wordScore = scoring.totalScore;

            // Combo detection and scoring.
            final ComboResult comboResult = await _combo.detect(result.word);

            if (comboResult.hasCombo) {
              // Initialise combo scoring engine if needed.
              if (_cachedRules?.scoring != null) {
                _comboScoringEngine ??= ComboScoringEngine(
                  scoringConfig: _cachedRules!.scoring!,
                );
              }

              if (_comboScoringEngine != null) {
                final ComboScoringResult comboScoring = _comboScoringEngine!
                    .scoreWithCombo(
                      mainWord: result.word,
                      mainWordScore: wordScore,
                      comboResult: comboResult,
                    );
                wordScore = comboScoring.totalScore;
                comboCount = comboScoring.comboCount;
                comboBonus = comboScoring.comboBonus;
              }
            }
          }

          List<BoardCell> newBoard = activeSession.board;
          final GameRulesConfig? rules = _cachedRules;
          if (rules != null) {
            final BoardResolveResult resolved = _resolver.resolve(
              board: activeSession.board,
              selectedCellIds: activeSession.selectedCellIds,
              gridSize: activeSession.gridSize,
              rules: rules.boardGeneration,
              wordLength: result.word.length,
            );
            newBoard = resolved.board;
            _lastRemovedCellIds = resolved.removedCells
                .map((BoardCell cell) => cell.id)
                .toList(growable: false);
          } else {
            _lastRemovedCellIds = const <String>[];
          }

          _lastWordScore = wordScore;
          _lastComboCount = comboCount;
          _lastComboBonus = comboBonus;
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

          // Post-move recovery: ensure the new board has at
          // least one playable word after refill. If not,
          // trigger recovery and recompute the word count.
          updatedSession = _ensurePostMovePlayability(updatedSession);

          _lastInvalidFeedback = null;
        } else {
          // Invalid attempt — recompute word count on the
          // unchanged board (it stays the same but we keep
          // the count consistent since moves decreased).
          updatedSession = activeSession.copyWith(
            selectedCellIds: const <String>[],
            movesLeft: newMovesLeft,
          );
          _lastRemovedCellIds = const <String>[];
          _lastWordScore = 0;
          _lastComboCount = 0;
          _lastComboBonus = 0;
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
        _lastComboCount = 0;
        _lastComboBonus = 0;
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

  // ── Post-move board analysis ────────────────────────────────

  /// Computes the non-overlapping playable word count for the
  /// given [session] using the cached dictionary.
  int _computePlayableWordCount(GameSession session) {
    final Set<String>? dictionary = _cachedDictionary;
    if (dictionary == null || dictionary.isEmpty) {
      return 0;
    }

    return _boardAnalyzer.countNonOverlappingWords(
      board: session.board,
      gridSize: session.gridSize,
      words: dictionary,
    );
  }

  /// Ensures the board in [session] has at least one playable word.
  ///
  /// If the board is dead after refill, triggers
  /// [BoardRecovery.ensurePlayable] and updates the playable word
  /// count.  Returns the (potentially recovered) session.
  GameSession _ensurePostMovePlayability(GameSession session) {
    final Set<String>? dictionary = _cachedDictionary;
    final GameRulesConfig? rules = _cachedRules;

    if (dictionary == null || rules == null) {
      // Without cached data we can't analyze — return as-is.
      return session.copyWith(playableWordCount: 0);
    }

    final bool isPlayable = _boardAnalyzer.hasPlayableWord(
      board: session.board,
      gridSize: session.gridSize,
      words: dictionary,
    );

    if (!isPlayable) {
      // Board is dead — trigger recovery.
      final BoardRecovery recovery = BoardRecovery(
        analyzer: _boardAnalyzer,
        boardGenerator: _boardGenerator,
      );

      try {
        session = recovery.ensurePlayable(
          session: session,
          dictionary: dictionary,
          rules: rules,
        );
      } catch (error) {
        debugPrint('post-move recovery failed: $error');
      }
    }

    return session.copyWith(
      playableWordCount: _computePlayableWordCount(session),
    );
  }
}
