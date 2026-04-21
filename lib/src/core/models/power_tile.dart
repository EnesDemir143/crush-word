enum PowerTileType {
  rowClear,
  areaBlast,
  columnClear,
  megaBlast;

  static PowerTileType fromName(String value) {
    return values.firstWhere(
      (PowerTileType power) => power.name == value,
      orElse: () {
        throw ArgumentError.value(
          value,
          'value',
          'Unknown power tile type name.',
        );
      },
    );
  }
}

class PowerTile {
  const PowerTile({required this.type});

  final PowerTileType type;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'type': type.name};
  }

  factory PowerTile.fromJson(Object? json) {
    if (json is String) {
      return PowerTile(type: PowerTileType.fromName(json));
    }

    if (json is Map<String, dynamic>) {
      final String typeName = (json['type'] as String?)?.trim() ?? '';
      if (typeName.isEmpty) {
        throw const FormatException('PowerTile requires a type value.');
      }

      return PowerTile(type: PowerTileType.fromName(typeName));
    }

    throw const FormatException(
      'PowerTile must be encoded as a string or map.',
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PowerTile && other.type == type;
  }

  @override
  int get hashCode => type.hashCode;
}
