import '../../../../core/database/database_helper.dart';
import '../models/wallet_model.dart';

class WalletRepository {
  Future<List<WalletModel>> getAll() async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query('wallets', orderBy: 'createdAt ASC');
    return maps.map(WalletModel.fromMap).toList();
  }

  Future<void> insert(WalletModel wallet) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('wallets', wallet.toMap());
  }

  Future<void> update(WalletModel wallet) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('wallets', wallet.toMap(),
        where: 'id = ?', whereArgs: [wallet.id]);
  }

  Future<void> delete(String id) async {
    final db = await DatabaseHelper.instance.database;
    // Don't allow deleting the default wallet
    if (id == 'default') return;
    await db.delete('wallets', where: 'id = ?', whereArgs: [id]);
    // Move expenses from deleted wallet to default
    await db.update('expenses', {'walletId': 'default'},
        where: 'walletId = ?', whereArgs: [id]);
  }
}
