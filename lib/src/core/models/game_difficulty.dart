enum GameDifficulty {
  easy,
  medium,
  hard;

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
}
