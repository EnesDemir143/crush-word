import 'dart:math';

import 'package:crush_word/src/core/config/game_rules_config.dart';
import 'package:crush_word/src/core/gameplay/models/board_cell.dart';
import 'package:crush_word/src/core/gameplay/models/game_session.dart';
import 'package:crush_word/src/core/gameplay/services/board_resolver.dart';

class JokerIds {
  const JokerIds._();

  static const String fish = 'fish';
  static const String wheel = 'wheel';
  static const String lollipopBreaker = 'lollipop_breaker';
  static const String freeSwap = 'free_swap';
  static const String shuffleLetters = 'shuffle_letters';
  static const String partyBooster = 'party_booster';
}

class JokerEffectResult {
  const JokerEffectResult({
    required this.applied,
    required this.board,
    this.removedCellIds = const <String>[],
  });

  factory JokerEffectResult.noop(List<BoardCell> board) {
    return JokerEffectResult(applied: false, board: board);
  }

  final bool applied;
  final List<BoardCell> board;
  final List<String> removedCellIds;
}

class JokerEngine {
  JokerEngine({Random? random}) : _random = random ?? Random();

  final Random _random;

  bool requiresTarget(String jokerId) {
    return jokerId == JokerIds.wheel ||
        jokerId == JokerIds.lollipopBreaker ||
        jokerId == JokerIds.freeSwap;
  }

  bool allowsSingleTarget(String jokerId) {
    return jokerId == JokerIds.wheel || jokerId == JokerIds.lollipopBreaker;
  }

  bool allowsDoubleTarget(String jokerId) {
    return jokerId == JokerIds.freeSwap;
  }

  JokerEffectResult apply({
    required String jokerId,
    required GameSession session,
    required GameRulesConfig rules,
    required BoardResolver boardResolver,
    List<String> selectedCellIds = const <String>[],
  }) {
    return switch (jokerId) {
      JokerIds.fish => _clearCells(
        session: session,
        boardResolver: boardResolver,
        rules: rules,
        targetCellIds: _pickRandomCellIds(session),
      ),
      JokerIds.wheel => _clearCells(
        session: session,
        boardResolver: boardResolver,
        rules: rules,
        targetCellIds: _wheelTargets(session, selectedCellIds),
      ),
      JokerIds.lollipopBreaker => _clearCells(
        session: session,
        boardResolver: boardResolver,
        rules: rules,
        targetCellIds: _singleTarget(selectedCellIds),
      ),
      JokerIds.freeSwap => _swapAdjacent(
        session: session,
        selectedCellIds: selectedCellIds,
      ),
      JokerIds.shuffleLetters => _shuffle(session),
      JokerIds.partyBooster => _clearCells(
        session: session,
        boardResolver: boardResolver,
        rules: rules,
        targetCellIds: session.board
            .map((BoardCell cell) => cell.id)
            .toList(growable: false),
      ),
      _ => JokerEffectResult.noop(session.board),
    };
  }

  JokerEffectResult _clearCells({
    required GameSession session,
    required BoardResolver boardResolver,
    required GameRulesConfig rules,
    required List<String> targetCellIds,
  }) {
    if (targetCellIds.isEmpty) {
      return JokerEffectResult.noop(session.board);
    }

    final BoardResolveResult resolved = boardResolver.resolve(
      board: session.board,
      selectedCellIds: targetCellIds,
      gridSize: session.gridSize,
      rules: rules.boardGeneration,
      wordLength: 0,
    );

    return JokerEffectResult(
      applied: true,
      board: resolved.board,
      removedCellIds: resolved.removedCells
          .map((BoardCell cell) => cell.id)
          .toList(growable: false),
    );
  }

  List<String> _pickRandomCellIds(GameSession session) {
    final int count = min(3, session.board.length);
    final List<int> shuffledIndexes = List<int>.generate(
      session.board.length,
      (int index) => index,
      growable: false,
    )..shuffle(_random);

    return shuffledIndexes
        .take(count)
        .map((int index) => session.board[index].id)
        .toList(growable: false);
  }

  List<String> _wheelTargets(
    GameSession session,
    List<String> selectedCellIds,
  ) {
    if (selectedCellIds.length != 1) {
      return const <String>[];
    }

    final BoardCell pivot = session.board.firstWhere(
      (BoardCell cell) => cell.id == selectedCellIds.single,
    );

    return session.board
        .where(
          (BoardCell cell) =>
              cell.row == pivot.row || cell.column == pivot.column,
        )
        .map((BoardCell cell) => cell.id)
        .toList(growable: false);
  }

  List<String> _singleTarget(List<String> selectedCellIds) {
    if (selectedCellIds.length != 1) {
      return const <String>[];
    }

    return <String>[selectedCellIds.single];
  }

  JokerEffectResult _swapAdjacent({
    required GameSession session,
    required List<String> selectedCellIds,
  }) {
    if (selectedCellIds.length != 2) {
      return JokerEffectResult.noop(session.board);
    }

    final BoardCell first = session.board.firstWhere(
      (BoardCell cell) => cell.id == selectedCellIds.first,
    );
    final BoardCell second = session.board.firstWhere(
      (BoardCell cell) => cell.id == selectedCellIds.last,
    );

    final int rowDelta = (first.row - second.row).abs();
    final int columnDelta = (first.column - second.column).abs();
    final bool adjacent =
        rowDelta <= 1 &&
        columnDelta <= 1 &&
        (rowDelta != 0 || columnDelta != 0);
    if (!adjacent) {
      return JokerEffectResult.noop(session.board);
    }

    final List<BoardCell> swappedBoard = session.board
        .map((BoardCell cell) {
          if (cell.id == first.id) {
            return second.copyWith(row: first.row, column: first.column);
          }
          if (cell.id == second.id) {
            return first.copyWith(row: second.row, column: second.column);
          }
          return cell;
        })
        .toList(growable: false);

    return JokerEffectResult(applied: true, board: swappedBoard);
  }

  JokerEffectResult _shuffle(GameSession session) {
    final List<BoardCell> shuffledCells = List<BoardCell>.from(session.board)
      ..shuffle(_random);

    final List<BoardCell> shuffledBoard = List<BoardCell>.generate(
      shuffledCells.length,
      (int index) => shuffledCells[index].copyWith(
        row: index ~/ session.gridSize,
        column: index % session.gridSize,
      ),
      growable: false,
    );

    return JokerEffectResult(applied: true, board: shuffledBoard);
  }
}
