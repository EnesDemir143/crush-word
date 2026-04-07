enum GameDifficulty {
  easy(label: 'Kolay', gridSize: 10, moveLimit: 25),
  medium(label: 'Orta', gridSize: 8, moveLimit: 20),
  hard(label: 'Zor', gridSize: 6, moveLimit: 15);

  const GameDifficulty({
    required this.label,
    required this.gridSize,
    required this.moveLimit,
  });

  final String label;
  final int gridSize;
  final int moveLimit;

  String get gridLabel => '${gridSize}x$gridSize';

  static GameDifficulty fromName(String value) {
    return values.firstWhere(
      (GameDifficulty difficulty) => difficulty.name == value,
      orElse: () {
        throw ArgumentError.value(
          value,
          'value',
          'Unknown game difficulty name.',
        );
      },
    );
  }

  static GameDifficulty fromGridSize(int gridSize) {
    return values.firstWhere(
      (GameDifficulty difficulty) => difficulty.gridSize == gridSize,
      orElse: () {
        throw ArgumentError.value(
          gridSize,
          'gridSize',
          'Unknown grid size for game difficulty.',
        );
      },
    );
  }
}
