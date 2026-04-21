import 'package:crush_word/src/core/config/game_rules_config.dart';
import 'package:crush_word/src/core/gameplay/models/board_cell.dart';
import 'package:crush_word/src/core/gameplay/services/board_generator.dart';
import 'package:crush_word/src/core/gameplay/services/power_engine.dart';
import 'package:crush_word/src/core/models/power_tile.dart';

/// Result of resolving a valid word on the board.
///
/// Contains the new board state after cells have been cleared,
/// columns collapsed downward and empty positions refilled.
class BoardResolveResult {
  const BoardResolveResult({
    required this.board,
    required this.removedCells,
    this.powerActivation,
    this.createdPower,
  });

  /// The board after clear → gravity → refill.
  final List<BoardCell> board;

  /// The cells that were removed (useful for future animations).
  final List<BoardCell> removedCells;

  /// Power activation details, if any power tiles were triggered.
  final PowerActivationResult? powerActivation;

  /// The power tile that was created on the surviving last letter, if any.
  final PowerTile? createdPower;
}

/// Pure service that resolves a valid word on the board.
///
/// The pipeline runs these deterministic steps:
/// 1. **Power activation** — if any selected cells carry a power,
///    compute additional cells to remove.
/// 2. **Clear** — remove selected cells + power-effect cells.
/// 3. **Gravity** — shift surviving cells down within each column.
/// 4. **Refill** — fill empty positions from the top with new
///    weighted-random letters via [BoardGenerator].
/// 5. **Power creation** — if the word was long enough, keep the
///    last letter in place and attach power metadata to that cell.
///
/// The resolver never touches session state directly.
class BoardResolver {
  const BoardResolver({
    required BoardGenerator boardGenerator,
    PowerEngine? powerEngine,
  }) : _boardGenerator = boardGenerator,
       _powerEngine = powerEngine;

  final BoardGenerator _boardGenerator;
  final PowerEngine? _powerEngine;

  /// Exposed for the controller to check if the resolver already
  /// has a power engine configured.
  PowerEngine? get powerEngine => _powerEngine;

  /// Resolve [selectedCellIds] on [board] for a grid of
  /// [gridSize] × [gridSize].
  ///
  /// [rules] is forwarded to the board generator for refill
  /// letter selection.  [wordLength] is used to determine whether
  /// a power tile should be created on the refreshed board.
  BoardResolveResult resolve({
    required List<BoardCell> board,
    required List<String> selectedCellIds,
    required int gridSize,
    required GameBoardGenerationRules rules,
    int? wordLength,
  }) {
    // Nothing to resolve — return the board as-is.
    if (selectedCellIds.isEmpty) {
      return BoardResolveResult(
        board: board,
        removedCells: const <BoardCell>[],
      );
    }

    // ── 0. Power activation ───────────────────────────────────
    final String lastSelectedId = selectedCellIds.last;
    final BoardCell lastSelectedCell = _cellById(board, lastSelectedId);
    final PowerTile? createdPower = _powerEngine?.powerForWord(wordLength ?? 0);
    final Set<String> preservedIds = createdPower == null
        ? const <String>{}
        : <String>{lastSelectedId};

    PowerActivationResult? powerActivation;
    Set<String> allRemovedIds = selectedCellIds.toSet()
      ..removeAll(preservedIds);

    if (_powerEngine != null) {
      final List<BoardCell> selectedCells = selectedCellIds
          .map((String id) => _cellById(board, id))
          .toList(growable: false);

      powerActivation = _powerEngine.activate(
        board: board,
        selectedCells: selectedCells,
      );

      if (powerActivation.hasActivation) {
        allRemovedIds = <String>{
          ...allRemovedIds,
          ...powerActivation.additionalRemovedIds,
        };
      }
    }

    // ── 1. Clear ────────────────────────────────────────────
    final List<BoardCell> removedCells = board
        .where((BoardCell cell) => allRemovedIds.contains(cell.id))
        .toList(growable: false);

    // ── 2. Gravity — per column, bottom-up ──────────────────
    // Build a column-major structure for easy manipulation.
    final List<List<BoardCell?>> columns = List<List<BoardCell?>>.generate(
      gridSize,
      (int col) => List<BoardCell?>.generate(gridSize, (int row) {
        final BoardCell cell = _cellAt(board, row, col);
        return allRemovedIds.contains(cell.id) ? null : cell;
      }, growable: true),
      growable: false,
    );

    // Collapse each column: remove nulls, pad top with nulls.
    // When a long word creates a power tile, the last selected cell
    // stays pinned in place, so cells above and below it collapse
    // independently within the same column.
    for (int col = 0; col < gridSize; col++) {
      final int pinnedRow =
          createdPower != null && col == lastSelectedCell.column
          ? lastSelectedCell.row
          : -1;

      if (pinnedRow == -1) {
        final List<BoardCell?> surviving = columns[col]
            .where((BoardCell? c) => c != null)
            .toList();

        final int emptyCount = gridSize - surviving.length;

        columns[col] = <BoardCell?>[
          ...List<BoardCell?>.filled(emptyCount, null),
          ...surviving,
        ];
        continue;
      }

      final List<BoardCell?> collapsedColumn = List<BoardCell?>.filled(
        gridSize,
        null,
      );
      collapsedColumn[pinnedRow] = columns[col][pinnedRow];

      final List<BoardCell?> topSurvivors = columns[col]
          .sublist(0, pinnedRow)
          .where((BoardCell? cell) => cell != null)
          .toList();
      final int topOffset = pinnedRow - topSurvivors.length;
      for (int index = 0; index < topSurvivors.length; index++) {
        collapsedColumn[topOffset + index] = topSurvivors[index];
      }

      final List<BoardCell?> bottomSurvivors = columns[col]
          .sublist(pinnedRow + 1)
          .where((BoardCell? cell) => cell != null)
          .toList();
      final int bottomStart = gridSize - bottomSurvivors.length;
      for (int index = 0; index < bottomSurvivors.length; index++) {
        collapsedColumn[bottomStart + index] = bottomSurvivors[index];
      }

      columns[col] = collapsedColumn;
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

    // ── 4. Power creation ───────────────────────────────────
    final List<BoardCell> finalBoard = createdPower == null
        ? newBoard
        : newBoard
              .map((BoardCell cell) {
                if (cell.row == lastSelectedCell.row &&
                    cell.column == lastSelectedCell.column) {
                  return cell.copyWith(power: createdPower);
                }
                return cell;
              })
              .toList(growable: false);

    return BoardResolveResult(
      board: finalBoard,
      removedCells: removedCells,
      powerActivation: powerActivation,
      createdPower: createdPower,
    );
  }

  BoardCell _cellAt(List<BoardCell> board, int row, int col) {
    return board.firstWhere((BoardCell c) => c.row == row && c.column == col);
  }

  BoardCell _cellById(List<BoardCell> board, String id) {
    return board.firstWhere((BoardCell c) => c.id == id);
  }
}
