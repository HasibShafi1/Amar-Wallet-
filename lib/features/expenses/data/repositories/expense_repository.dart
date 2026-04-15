import 'package:flutter_riverpod/flutter_riverpod.dart';
export 'package:sqflite/sqflite.dart' show ConflictAlgorithm;
import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../models/expense_model.dart';
import '../models/tag_model.dart';

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepository();
});

class ExpenseRepository {
  final dbHelper = DatabaseHelper.instance;

  Future<void> addExpense(ExpenseModel expense) async {
    final db = await dbHelper.database;
    await db.insert('expenses', expense.toMap());
    // Save tags
    for (final tag in expense.tags) {
      await _ensureTag(tag);
      await db.insert('expense_tags', {
        'expenseId': expense.id,
        'tagName': tag,
      });
    }
  }

  Future<List<ExpenseModel>> getExpenses({String? walletId}) async {
    final db = await dbHelper.database;
    List<Map<String, Object?>> maps;
    if (walletId != null) {
      maps = await db.query('expenses',
          where: 'walletId = ?',
          whereArgs: [walletId],
          orderBy: 'createdAt DESC');
    } else {
      maps = await db.query('expenses', orderBy: 'createdAt DESC');
    }

    final expenses = <ExpenseModel>[];
    for (final map in maps) {
      final id = map['id'] as String;
      final tagMaps = await db.query('expense_tags',
          where: 'expenseId = ?', whereArgs: [id]);
      final tags = tagMaps.map((t) => t['tagName'] as String).toList();
      expenses.add(ExpenseModel.fromMap(map, tags: tags));
    }
    return expenses;
  }

  Future<void> updateExpense(ExpenseModel expense) async {
    final db = await dbHelper.database;
    await db.update('expenses', expense.toMap(),
        where: 'id = ?', whereArgs: [expense.id]);
    // Update tags: clear old, insert new
    await db.delete('expense_tags',
        where: 'expenseId = ?', whereArgs: [expense.id]);
    for (final tag in expense.tags) {
      await _ensureTag(tag);
      await db.insert('expense_tags', {
        'expenseId': expense.id,
        'tagName': tag,
      });
    }
  }

  Future<void> deleteExpense(String id) async {
    final db = await dbHelper.database;
    await db.delete('expense_tags', where: 'expenseId = ?', whereArgs: [id]);
    await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  // ── Tag operations ─────────────────────────────────────────────────────────

  Future<void> _ensureTag(String name) async {
    final db = await dbHelper.database;
    await db.insert('tags', TagModel(name: name).toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<List<TagModel>> getAllTags() async {
    final db = await dbHelper.database;
    final maps = await db.query('tags', orderBy: 'name ASC');
    return maps.map(TagModel.fromMap).toList();
  }

  Future<void> addTagToExpense(String expenseId, String tagName) async {
    final db = await dbHelper.database;
    await _ensureTag(tagName);
    await db.insert('expense_tags', {
      'expenseId': expenseId,
      'tagName': tagName,
    });
  }

  Future<void> removeTagFromExpense(String expenseId, String tagName) async {
    final db = await dbHelper.database;
    await db.delete('expense_tags',
        where: 'expenseId = ? AND tagName = ?',
        whereArgs: [expenseId, tagName]);
  }

  Future<List<ExpenseModel>> getExpensesByTag(String tagName) async {
    final db = await dbHelper.database;
    final maps = await db.rawQuery('''
      SELECT e.* FROM expenses e
      INNER JOIN expense_tags et ON e.id = et.expenseId
      WHERE et.tagName = ?
      ORDER BY e.createdAt DESC
    ''', [tagName]);

    final expenses = <ExpenseModel>[];
    for (final map in maps) {
      final id = map['id'] as String;
      final tagMaps = await db.query('expense_tags',
          where: 'expenseId = ?', whereArgs: [id]);
      final tags = tagMaps.map((t) => t['tagName'] as String).toList();
      expenses.add(ExpenseModel.fromMap(map, tags: tags));
    }
    return expenses;
  }
}

// Empty line
