import 'package:crush_word/src/core/persistence/sqlite/app_database.dart';
import 'package:sqflite/sqflite.dart';

class WalletRepository {
  WalletRepository({AppDatabase? database, this.initialGold = 9999})
    : _database = database ?? AppDatabase();

  static const String walletId = 'player_wallet';

  final AppDatabase _database;
  final int initialGold;

  Future<int> loadGoldBalance({DatabaseExecutor? executor}) async {
    final DatabaseExecutor resolvedExecutor = await _resolveExecutor(executor);
    await _ensureWalletRow(resolvedExecutor);

    final List<Map<String, Object?>> rows = await resolvedExecutor.query(
      'wallet_balance',
      columns: <String>['gold_balance'],
      where: 'wallet_id = ?',
      whereArgs: <Object>[walletId],
      limit: 1,
    );

    return (rows.single['gold_balance'] as num).toInt();
  }

  Future<void> setGoldBalance(
    int goldBalance, {
    DatabaseExecutor? executor,
  }) async {
    final DatabaseExecutor resolvedExecutor = await _resolveExecutor(executor);
    await _ensureWalletRow(resolvedExecutor);

    await resolvedExecutor.update(
      'wallet_balance',
      <String, Object?>{'gold_balance': goldBalance},
      where: 'wallet_id = ?',
      whereArgs: <Object>[walletId],
    );
  }

  Future<DatabaseExecutor> _resolveExecutor(DatabaseExecutor? executor) async {
    return executor ?? await _database.database;
  }

  Future<void> _ensureWalletRow(DatabaseExecutor executor) async {
    final List<Map<String, Object?>> rows = await executor.query(
      'wallet_balance',
      columns: <String>['wallet_id'],
      where: 'wallet_id = ?',
      whereArgs: <Object>[walletId],
      limit: 1,
    );

    if (rows.isNotEmpty) {
      return;
    }

    await executor.insert('wallet_balance', <String, Object?>{
      'wallet_id': walletId,
      'gold_balance': initialGold,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }
}
