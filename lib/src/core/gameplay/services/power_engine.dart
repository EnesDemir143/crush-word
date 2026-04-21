import 'package:crush_word/src/core/config/game_rules_config.dart';
import 'package:crush_word/src/core/gameplay/models/board_cell.dart';
import 'package:crush_word/src/core/models/power_tile.dart';

/// Result of activating power tiles during a word resolution.
class PowerActivationResult {
  const PowerActivationResult({
    required this.additionalRemovedIds,
    required this.activatedPowers,
  });

  final Set<String> additionalRemovedIds;
  final List<PowerTileType> activatedPowers;

  bool get hasActivation => activatedPowers.isNotEmpty;
}

/// Pure service that handles power-tile creation and activation.
class PowerEngine {
  const PowerEngine({required PowerTileConfig config}) : _config = config;

  final PowerTileConfig _config;

  PowerTile? powerForWord(int wordLength) {
    final PowerTileType? powerType = _config.powerForWordLength(wordLength);
    return powerType == null ? null : PowerTile(type: powerType);
  }

  PowerActivationResult activate({
    required List<BoardCell> board,
    required List<BoardCell> selectedCells,
  }) {
    final Set<String> additionalIds = <String>{};
    final List<PowerTileType> activatedPowers = <PowerTileType>[];
    final Set<String> selectedIds = selectedCells
        .map((BoardCell cell) => cell.id)
        .toSet();

    for (final BoardCell cell in selectedCells) {
      final PowerTile? power = cell.power;
      if (power == null) {
        continue;
      }

      activatedPowers.add(power.type);

      switch (power.type) {
        case PowerTileType.rowClear:
          for (final BoardCell target in board) {
            if (target.row == cell.row && !selectedIds.contains(target.id)) {
              additionalIds.add(target.id);
            }
          }

        case PowerTileType.columnClear:
          for (final BoardCell target in board) {
            if (target.column == cell.column &&
                !selectedIds.contains(target.id)) {
              additionalIds.add(target.id);
            }
          }

        case PowerTileType.areaBlast:
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

        case PowerTileType.megaBlast:
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
