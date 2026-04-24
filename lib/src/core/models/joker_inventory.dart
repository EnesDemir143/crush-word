class JokerInventory {
  const JokerInventory({required this.jokerId, required this.quantity})
    : assert(quantity >= 0, 'Joker quantity cannot be negative.');

  final String jokerId;
  final int quantity;

  JokerInventory copyWith({String? jokerId, int? quantity}) {
    return JokerInventory(
      jokerId: jokerId ?? this.jokerId,
      quantity: quantity ?? this.quantity,
    );
  }

  Map<String, Object?> toRow() {
    return <String, Object?>{'joker_id': jokerId, 'quantity': quantity};
  }

  factory JokerInventory.fromRow(Map<String, Object?> row) {
    return JokerInventory(
      jokerId: (row['joker_id'] as String?)?.trim() ?? '',
      quantity: (row['quantity'] as num?)?.toInt() ?? 0,
    );
  }
}
