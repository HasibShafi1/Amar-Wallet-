import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database_helper.dart';
import '../models/expense_model.dart';

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepository();
});

class ExpenseRepository {
  final dbHelper = DatabaseHelper.instance;

  Future<void> addExpense(ExpenseModel expense) async {
    final db = await dbHelper.database;
    await db.insert('expenses', expense.toMap());
  }

  Future<List<ExpenseModel>> getExpenses() async {
    final db = await dbHelper.database;
    final List<Map<String, Object?>> maps = await db.query(
      'expenses',
      orderBy: 'createdAt DESC',
    );

    return maps.map((map) => ExpenseModel.fromMap(map)).toList();
  }

  Future<void> updateExpense(ExpenseModel expense) async {
    final db = await dbHelper.database;
    await db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<void> deleteExpense(String id) async {
    final db = await dbHelper.database;
    await db.delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
