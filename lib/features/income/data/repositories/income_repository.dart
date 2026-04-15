import '../../../../core/database/database_helper.dart';
import '../models/income_model.dart';

class IncomeRepository {
  final _db = DatabaseHelper.instance;

  Future<List<IncomeModel>> getAll() async {
    final db = await _db.database;
    final maps = await db.query('income', orderBy: 'date DESC');
    return maps.map(IncomeModel.fromMap).toList();
  }

  Future<List<IncomeModel>> getByMonth(int year, int month) async {
    final db = await _db.database;
    final from = DateTime(year, month, 1).toIso8601String();
    final to = DateTime(year, month + 1, 1).toIso8601String();
    final maps = await db.query(
      'income',
      where: 'date >= ? AND date < ?',
      whereArgs: [from, to],
    );
    return maps.map(IncomeModel.fromMap).toList();
  }

  Future<void> insert(IncomeModel income) async {
    final db = await _db.database;
    await db.insert('income', income.toMap());
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete('income', where: 'id = ?', whereArgs: [id]);
  }

  Future<double> getTotalIncome() async {
    final db = await _db.database;
    final result = await db.rawQuery('SELECT SUM(amount) as total FROM income');
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }
}
