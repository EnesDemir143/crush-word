import 'package:crush_word/src/core/models/joker_inventory.dart';
import 'package:crush_word/src/core/persistence/sqlite/app_database.dart';
import 'package:sqflite/sqflite.dart';

class JokerInventoryRepository {
  JokerInventoryRepository({AppDatabase? database})
    : _database = database ?? AppDatabase();

  final AppDatabase _database;

  Future<List<JokerInventory>> loadInventory({
    DatabaseExecutor? executor,
  }) async {
    final DatabaseExecutor resolvedExecutor = await _resolveExecutor(executor);
    final List<Map<String, Object?>> rows = await resolvedExecutor.query(
      'joker_inventory',
      orderBy: 'joker_id ASC',
    );

    return rows
        .map((Map<String, Object?> row) => JokerInventory.fromRow(row))
        .toList(growable: false);
  }

  Future<int> quantityFor(String jokerId, {DatabaseExecutor? executor}) async {
    final DatabaseExecutor resolvedExecutor = await _resolveExecutor(executor);
    final List<Map<String, Object?>> rows = await resolvedExecutor.query(
      'joker_inventory',
      columns: <String>['quantity'],
      where: 'joker_id = ?',
      whereArgs: <Object>[jokerId],
      limit: 1,
    );

    if (rows.isEmpty) {
      return 0;
    }

    return (rows.single['quantity'] as num?)?.toInt() ?? 0;
  }

  Future<void> setQuantity(
    String jokerId,
    int quantity, {
    DatabaseExecutor? executor,
  }) async {
    final DatabaseExecutor resolvedExecutor = await _resolveExecutor(executor);
    await resolvedExecutor.insert(
      'joker_inventory',
      JokerInventory(jokerId: jokerId, quantity: quantity).toRow(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<DatabaseExecutor> _resolveExecutor(DatabaseExecutor? executor) async {
    return executor ?? await _database.database;
  }
}
