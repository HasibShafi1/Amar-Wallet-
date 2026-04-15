import '../../../../core/database/database_helper.dart';
import '../models/subscription_model.dart';

class SubscriptionRepository {
  Future<List<SubscriptionModel>> getAll() async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query('subscriptions', orderBy: 'nextDueDate ASC');
    return maps.map(SubscriptionModel.fromMap).toList();
  }

  Future<List<SubscriptionModel>> getActive() async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query('subscriptions',
        where: 'isActive = ?', whereArgs: [1], orderBy: 'nextDueDate ASC');
    return maps.map(SubscriptionModel.fromMap).toList();
  }

  Future<List<SubscriptionModel>> getDueSoon() async {
    final db = await DatabaseHelper.instance.database;
    final threeDaysLater =
        DateTime.now().add(const Duration(days: 3)).toIso8601String();
    final maps = await db.query('subscriptions',
        where: 'isActive = ? AND nextDueDate <= ?',
        whereArgs: [1, threeDaysLater],
        orderBy: 'nextDueDate ASC');
    return maps.map(SubscriptionModel.fromMap).toList();
  }

  Future<void> insert(SubscriptionModel sub) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('subscriptions', sub.toMap());
  }

  Future<void> update(SubscriptionModel sub) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('subscriptions', sub.toMap(),
        where: 'id = ?', whereArgs: [sub.id]);
  }

  Future<void> toggleActive(String id, bool active) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('subscriptions', {'isActive': active ? 1 : 0},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> delete(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('subscriptions', where: 'id = ?', whereArgs: [id]);
  }
}
