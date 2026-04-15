import '../../../../core/database/database_helper.dart';
import '../models/goal_model.dart';

class GoalRepository {
  final _db = DatabaseHelper.instance;

  Future<List<GoalModel>> getAll() async {
    final db = await _db.database;
    final maps = await db.query('goals', orderBy: 'createdAt DESC');
    return maps.map(GoalModel.fromMap).toList();
  }

  Future<void> insert(GoalModel goal) async {
    final db = await _db.database;
    await db.insert('goals', goal.toMap());
  }

  Future<void> update(GoalModel goal) async {
    final db = await _db.database;
    await db.update('goals', goal.toMap(), where: 'id = ?', whereArgs: [goal.id]);
  }

  Future<void> addToSaved(String id, double amount) async {
    final db = await _db.database;
    await db.rawUpdate(
      'UPDATE goals SET savedAmount = savedAmount + ? WHERE id = ?',
      [amount, id],
    );
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete('goals', where: 'id = ?', whereArgs: [id]);
  }
}
