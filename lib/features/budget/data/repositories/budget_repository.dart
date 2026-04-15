import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../models/budget_model.dart';

class BudgetRepository {
  final _db = DatabaseHelper.instance;

  Future<List<BudgetModel>> getAll() async {
    final db = await _db.database;
    final maps = await db.query('budgets');
    return maps.map(BudgetModel.fromMap).toList();
  }

  Future<BudgetModel?> getByCategory(String category) async {
    final db = await _db.database;
    final maps = await db.query('budgets', where: 'category = ?', whereArgs: [category]);
    if (maps.isEmpty) return null;
    return BudgetModel.fromMap(maps.first);
  }

  Future<void> upsert(BudgetModel budget) async {
    final db = await _db.database;
    await db.insert(
      'budgets',
      budget.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> delete(String category) async {
    final db = await _db.database;
    await db.delete('budgets', where: 'category = ?', whereArgs: [category]);
  }
}
