import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/goal_model.dart';
import '../../data/repositories/goal_repository.dart';

final goalRepositoryProvider = Provider((_) => GoalRepository());

final goalListProvider =
    AsyncNotifierProvider<GoalListNotifier, List<GoalModel>>(
        GoalListNotifier.new);

class GoalListNotifier extends AsyncNotifier<List<GoalModel>> {
  @override
  Future<List<GoalModel>> build() async {
    return ref.read(goalRepositoryProvider).getAll();
  }

  Future<void> add(GoalModel goal) async {
    await ref.read(goalRepositoryProvider).insert(goal);
    ref.invalidateSelf();
  }

  Future<void> updateGoal(GoalModel goal) async {
    await ref.read(goalRepositoryProvider).update(goal);
    ref.invalidateSelf();
  }

  Future<void> addToSaved(String id, double amount) async {
    await ref.read(goalRepositoryProvider).addToSaved(id, amount);
    ref.invalidateSelf();
  }

  Future<void> remove(String id) async {
    await ref.read(goalRepositoryProvider).delete(id);
    ref.invalidateSelf();
  }
}
