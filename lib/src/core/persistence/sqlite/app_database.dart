import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase({
    DatabaseFactory? databaseFactory,
    Future<String> Function()? databaseDirectoryProvider,
    String? databasePath,
  }) : _databaseFactory = databaseFactory ?? databaseFactorySqflitePlugin,
       _databaseDirectoryProvider =
           databaseDirectoryProvider ?? getDatabasesPath,
       _databasePath = databasePath;

  static const String databaseName = 'word_crush.db';
  static const int schemaVersion = 2;

  final DatabaseFactory _databaseFactory;
  final Future<String> Function() _databaseDirectoryProvider;
  final String? _databasePath;

  Database? _database;

  Future<Database> get database async {
    final Database? existingDatabase = _database;

    if (existingDatabase != null && existingDatabase.isOpen) {
      return existingDatabase;
    }

    final Database openedDatabase = await _openDatabase();
    _database = openedDatabase;
    return openedDatabase;
  }

  Future<void> close() async {
    final Database? database = _database;
    _database = null;

    if (database != null && database.isOpen) {
      await database.close();
    }
  }

  Future<String> resolveDatabasePath() async {
    final String? explicitPath = _databasePath;
    if (explicitPath != null) {
      return explicitPath;
    }

    final String databaseDirectory = await _databaseDirectoryProvider();
    return p.join(databaseDirectory, databaseName);
  }

  Future<Database> _openDatabase() async {
    final String databasePath = await resolveDatabasePath();

    return _databaseFactory.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: schemaVersion,
        onConfigure: (Database db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (Database db, int version) async {
          await _createGameResultsTable(db);
          await _createSessionCheckpointTable(db);
          await _createWalletTable(db);
          await _createJokerInventoryTable(db);
        },
        onUpgrade: (Database db, int oldVersion, int _) async {
          if (oldVersion < 2) {
            await _createWalletTable(db);
            await _createJokerInventoryTable(db);
          }
        },
      ),
    );
  }

  Future<void> _createGameResultsTable(Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS game_results (
  id TEXT PRIMARY KEY,
  completed_at TEXT NOT NULL,
  difficulty TEXT NOT NULL,
  grid_size INTEGER NOT NULL,
  starting_moves INTEGER NOT NULL,
  score INTEGER NOT NULL,
  words_found_count INTEGER NOT NULL,
  longest_word TEXT NOT NULL,
  duration_seconds INTEGER NOT NULL
)
''');
  }

  Future<void> _createSessionCheckpointTable(Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS session_checkpoint (
  checkpoint_id TEXT PRIMARY KEY,
  game_config_json TEXT NOT NULL,
  board_json TEXT NOT NULL,
  remaining_moves INTEGER NOT NULL,
  elapsed_seconds INTEGER NOT NULL,
  current_score INTEGER NOT NULL,
  words_found_count INTEGER NOT NULL,
  longest_word TEXT NOT NULL,
  selected_path_json TEXT NOT NULL,
  power_tiles_json TEXT NOT NULL,
  updated_at TEXT NOT NULL
)
''');
  }

  Future<void> _createWalletTable(Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS wallet_balance (
  wallet_id TEXT PRIMARY KEY,
  gold_balance INTEGER NOT NULL
)
''');
  }

  Future<void> _createJokerInventoryTable(Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS joker_inventory (
  joker_id TEXT PRIMARY KEY,
  quantity INTEGER NOT NULL
)
''');
  }
}
