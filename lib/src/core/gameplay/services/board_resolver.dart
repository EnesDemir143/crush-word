import 'package:crush_word/src/core/config/game_rules_config.dart';
import 'package:crush_word/src/core/gameplay/models/board_cell.dart';
import 'package:crush_word/src/core/gameplay/services/board_generator.dart';

/// Result of resolving a valid word on the board.
///
/// Contains the new board state after cells have been cleared,
/// columns collapsed downward and empty positions refilled.
class BoardResolveResult {
  const BoardResolveResult({required this.board, required this.removedCells});

  /// The board after clear → gravity → refill.
  final List<BoardCell> board;

  /// The cells that were removed (useful for future animations).
  final List<BoardCell> removedCells;
}

/// Pure service that resolves a valid word on the board.
///
/// The pipeline runs three deterministic steps:
/// 1. **Clear** — remove cells on the selected path.
/// 2. **Gravity** — shift surviving cells down within each column.
/// 3. **Refill** — fill empty positions from the top with new
///    weighted-random letters via [BoardGenerator].
///
/// The resolver never touches session state directly.
class BoardResolver {
  const BoardResolver({required BoardGenerator boardGenerator})
    : _boardGenerator = boardGenerator;

  final BoardGenerator _boardGenerator;

  /// Resolve [selectedCellIds] on [board] for a grid of
  /// [gridSize] × [gridSize].
  ///
  /// [rules] is forwarded to the board generator for refill
  /// letter selection.
  BoardResolveResult resolve({
    required List<BoardCell> board,
    required List<String> selectedCellIds,
    required int gridSize,
    required GameBoardGenerationRules rules,
  }) {
    // ── 1. Clear ────────────────────────────────────────────
    final Set<String> removedIds = selectedCellIds.toSet();

    final List<BoardCell> removedCells = board
        .where((BoardCell cell) => removedIds.contains(cell.id))
        .toList(growable: false);

    // ── 2. Gravity — per column, bottom-up ──────────────────
    // Build a column-major structure for easy manipulation.
    final List<List<BoardCell?>> columns = List<List<BoardCell?>>.generate(
      gridSize,
      (int col) => List<BoardCell?>.generate(gridSize, (int row) {
        final BoardCell cell = _cellAt(board, row, col);
        return removedIds.contains(cell.id) ? null : cell;
      }, growable: true),
      growable: false,
    );

    // Collapse each column: remove nulls, pad top with nulls.
    for (int col = 0; col < gridSize; col++) {
      final List<BoardCell?> surviving = columns[col]
          .where((BoardCell? c) => c != null)
          .toList();

      final int emptyCount = gridSize - surviving.length;

      columns[col] = <BoardCell?>[
        ...List<BoardCell?>.filled(emptyCount, null),
        ...surviving,
      ];
    }

    // ── 3. Refill & reassign coordinates ────────────────────
    final List<BoardCell> newBoard = <BoardCell>[];

    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        final BoardCell? existing = columns[col][row];

        if (existing != null) {
          // Reassign row/col since gravity may have moved it.
          newBoard.add(existing.copyWith(row: row, column: col));
        } else {
          // Empty slot — generate a new letter.
          newBoard.add(
            BoardCell(
              row: row,
              column: col,
              letter: _boardGenerator.pickWeightedLetter(rules),
            ),
          );
        }
      }
    }

    return BoardResolveResult(board: newBoard, removedCells: removedCells);
  }

  BoardCell _cellAt(List<BoardCell> board, int row, int col) {
    return board.firstWhere((BoardCell c) => c.row == row && c.column == col);
  }
}
