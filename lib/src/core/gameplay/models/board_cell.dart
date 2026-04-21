import 'package:crush_word/src/core/models/power_tile.dart';

class BoardCell {
  const BoardCell({
    required this.row,
    required this.column,
    required this.letter,
    this.power,
    this.isJoker = false,
  });

  final int row;
  final int column;
  final String letter;
  final PowerTile? power;
  final bool isJoker;

  String get id => '$row:$column';

  BoardCell copyWith({
    int? row,
    int? column,
    String? letter,
    PowerTile? power,
    bool clearPower = false,
    bool? isJoker,
  }) {
    return BoardCell(
      row: row ?? this.row,
      column: column ?? this.column,
      letter: letter ?? this.letter,
      power: clearPower ? null : power ?? this.power,
      isJoker: isJoker ?? this.isJoker,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'row': row,
      'column': column,
      'letter': letter,
      'power': power?.toJson(),
      'isJoker': isJoker,
    };
  }

  factory BoardCell.fromJson(Map<String, dynamic> json) {
    final int? row = (json['row'] as num?)?.toInt();
    final int? column = (json['column'] as num?)?.toInt();
    final String letter = (json['letter'] as String?)?.trim() ?? '';
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
        other.power == power &&
        other.isJoker == isJoker;
  }

  @override
  int get hashCode => Object.hash(row, column, letter, power, isJoker);
}
