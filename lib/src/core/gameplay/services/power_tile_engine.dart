import 'package:crush_word/src/core/config/game_rules_config.dart';
import 'package:crush_word/src/core/gameplay/models/board_cell.dart';

/// Result of activating power tiles during a word resolution.
///
/// Contains the set of additional cell IDs that should be removed
/// from the board as a result of power effects.  The caller merges
/// these with the normally-selected cells before running gravity
/// and refill.
class PowerActivationResult {
  const PowerActivationResult({
    required this.additionalRemovedIds,
    required this.activatedPowers,
  });

  /// Cell IDs removed by power effects (does not include the
  /// normally-selected word cells).
  final Set<String> additionalRemovedIds;

  /// Which power types were activated, for UI feedback.
  final List<BoardCellPower> activatedPowers;

  /// Whether any power was activated.
  bool get hasActivation => additionalRemovedIds.isNotEmpty;
}

/// Pure service that handles power-tile creation and activation.
///
/// **Creation**: After a valid word is resolved, the engine
/// determines whether the word length earns a power tile.  If so,
/// it returns the [BoardCellPower] to place on the last cell's
/// position on the refreshed board.
///
/// **Activation**: When a word's path includes cells that carry a
/// power, the engine computes the additional cells that should be
/// removed from the board.
class PowerTileEngine {
  const PowerTileEngine({required PowerTileConfig config})
    : _config = config;

  final PowerTileConfig _config;

  /// Determines which power (if any) a word of [wordLength] earns.
  ///
  /// Returns `null` when the word is too short for any power.
  BoardCellPower? powerForWord(int wordLength) {
    return _config.powerForWordLength(wordLength);
  }

  /// Activates all power tiles found in [selectedCells] and
  /// computes the additional cells that should be removed.
  ///
  /// [board] is the full board state **before** any cells are
  /// removed.  [gridSize] is the board dimension.
  PowerActivationResult activate({
    required List<BoardCell> board,
    required List<BoardCell> selectedCells,
    required int gridSize,
  }) {
    final Set<String> additionalIds = <String>{};
    final List<BoardCellPower> activatedPowers = <BoardCellPower>[];

    // Collect the IDs of cells that are already being removed
    // (the word path) so we don't double-count them.
    final Set<String> selectedIds =
        selectedCells.map((BoardCell c) => c.id).toSet();

    for (final BoardCell cell in selectedCells) {
      if (cell.power == null) {
        continue;
      }

      activatedPowers.add(cell.power!);

      switch (cell.power!) {
        case BoardCellPower.rowClear:
          // Remove all cells in the same row.
          for (final BoardCell target in board) {
            if (target.row == cell.row && !selectedIds.contains(target.id)) {
              additionalIds.add(target.id);
            }
          }

        case BoardCellPower.columnClear:
          // Remove all cells in the same column.
          for (final BoardCell target in board) {
            if (target.column == cell.column &&
                !selectedIds.contains(target.id)) {
              additionalIds.add(target.id);
            }
          }

        case BoardCellPower.areaBlast:
          // Remove cells within areaBlastRadius of the power cell.
          final int radius = _config.areaBlastRadius;
          for (final BoardCell target in board) {
            if (selectedIds.contains(target.id)) {
              continue;
            }
            if ((target.row - cell.row).abs() <= radius &&
                (target.column - cell.column).abs() <= radius) {
              additionalIds.add(target.id);
            }
          }

        case BoardCellPower.megaBlast:
          // Remove cells within megaBlastRadius of the power cell.
          final int radius = _config.megaBlastRadius;
          for (final BoardCell target in board) {
            if (selectedIds.contains(target.id)) {
              continue;
            }
            if ((target.row - cell.row).abs() <= radius &&
                (target.column - cell.column).abs() <= radius) {
              additionalIds.add(target.id);
            }
          }
      }
    }

    return PowerActivationResult(
      additionalRemovedIds: additionalIds,
      activatedPowers: activatedPowers,
    );
  }
}
