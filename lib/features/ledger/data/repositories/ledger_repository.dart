import '../../../../core/database/database_helper.dart';
import '../models/ledger_model.dart';

class LedgerRepository {
  final _db = DatabaseHelper.instance;

  Future<List<LedgerModel>> getAll() async {
    final db = await _db.database;
    final maps = await db.query('ledger', orderBy: 'date DESC');
    return maps.map(LedgerModel.fromMap).toList();
  }

  Future<List<LedgerModel>> getByType(String type) async {
    final db = await _db.database;
    final maps = await db.query(
      'ledger',
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'date DESC',
    );
    return maps.map(LedgerModel.fromMap).toList();
  }

  Future<void> insert(LedgerModel entry) async {
    final db = await _db.database;
    await db.insert('ledger', entry.toMap());
  }

  Future<void> markAsPaid(String id) async {
    final db = await _db.database;
    await db.update('ledger', {'isPaid': 1}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete('ledger', where: 'id = ?', whereArgs: [id]);
  }

  Future<double> getPendingLentTotal() async {
    final db = await _db.database;
    final result = await db.rawQuery(
        "SELECT SUM(amount) as total FROM ledger WHERE type='lent' AND isPaid=0");
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<double> getPendingBorrowedTotal() async {
    final db = await _db.database;
    final result = await db.rawQuery(
        "SELECT SUM(amount) as total FROM ledger WHERE type='borrowed' AND isPaid=0");
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }
}
