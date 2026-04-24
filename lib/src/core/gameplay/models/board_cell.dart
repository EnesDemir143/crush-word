import 'package:crush_word/src/core/models/power_tile.dart';

class BoardCell {
  const BoardCell({
    required this.row,
    required this.column,
    required this.letter,
    this.tileId,
    this.power,
    this.isJoker = false,
  });

  final int row;
  final int column;
  final String letter;
  final String? tileId;
  final PowerTile? power;
  final bool isJoker;

  String get id => '$row:$column';

  /// Stable identity for a logical tile across row/column moves.
  ///
  /// UI animation uses this value to distinguish a falling survivor
  /// from a newly spawned refill tile.
  String get animationId => tileId ?? id;

  BoardCell copyWith({
    int? row,
    int? column,
    String? letter,
    String? tileId,
    PowerTile? power,
    bool clearPower = false,
    bool? isJoker,
  }) {
    return BoardCell(
      row: row ?? this.row,
      column: column ?? this.column,
      letter: letter ?? this.letter,
      tileId: tileId ?? this.tileId ?? id,
      power: clearPower ? null : power ?? this.power,
      isJoker: isJoker ?? this.isJoker,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'row': row,
      'column': column,
      'letter': letter,
      'tileId': tileId,
      'power': power?.toJson(),
      'isJoker': isJoker,
    };
  }

  factory BoardCell.fromJson(Map<String, dynamic> json) {
    final int? row = (json['row'] as num?)?.toInt();
    final int? column = (json['column'] as num?)?.toInt();
    final String letter = (json['letter'] as String?)?.trim() ?? '';
    final String? tileId = (json['tileId'] as String?)?.trim();
    final Object? powerJson = json['power'];
    final bool isJoker = json['isJoker'] as bool? ?? false;

    if (row == null || column == null || letter.isEmpty) {
      throw const FormatException(
        'BoardCell requires row, column and letter values.',
      );
    }

    return BoardCell(
      row: row,
      column: column,
      letter: letter,
      tileId: tileId == null || tileId.isEmpty ? null : tileId,
      power: powerJson == null ? null : PowerTile.fromJson(powerJson),
      isJoker: isJoker,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is BoardCell &&
        other.row == row &&
        other.column == column &&
        other.letter == letter &&
        other.tileId == tileId &&
        other.power == power &&
        other.isJoker == isJoker;
  }

  @override
  int get hashCode => Object.hash(row, column, letter, tileId, power, isJoker);
}
