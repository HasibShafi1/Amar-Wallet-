import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/budget_model.dart';
import '../../data/repositories/budget_repository.dart';

final budgetRepositoryProvider = Provider((_) => BudgetRepository());

final budgetListProvider =
    AsyncNotifierProvider<BudgetListNotifier, List<BudgetModel>>(
        BudgetListNotifier.new);

/// Map from category → budget model, for fast lookup
final budgetMapProvider = FutureProvider<Map<String, BudgetModel>>((ref) async {
  final budgets = await ref.watch(budgetListProvider.future);
  return {for (final b in budgets) b.category: b};
});

class BudgetListNotifier extends AsyncNotifier<List<BudgetModel>> {
  @override
  Future<List<BudgetModel>> build() async {
    return ref.read(budgetRepositoryProvider).getAll();
  }

  Future<void> upsertBudget(String category, double limit) async {
    await ref.read(budgetRepositoryProvider).upsert(
          BudgetModel(category: category, monthlyLimit: limit),
        );
    ref.invalidateSelf();
  }

  Future<void> deleteBudget(String category) async {
    await ref.read(budgetRepositoryProvider).delete(category);
    ref.invalidateSelf();
  }
}
