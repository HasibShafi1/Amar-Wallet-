import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/income_model.dart';
import '../../data/repositories/income_repository.dart';

final incomeRepositoryProvider = Provider((_) => IncomeRepository());

final incomeListProvider =
    AsyncNotifierProvider<IncomeListNotifier, List<IncomeModel>>(
        IncomeListNotifier.new);

final totalIncomeProvider = FutureProvider<double>((ref) async {
  final incomes = await ref.watch(incomeListProvider.future);
  return incomes.fold<double>(0.0, (sum, i) => sum + i.amount);
});

class IncomeListNotifier extends AsyncNotifier<List<IncomeModel>> {
  @override
  Future<List<IncomeModel>> build() async {
    return ref.read(incomeRepositoryProvider).getAll();
  }

  Future<void> add(IncomeModel income) async {
    await ref.read(incomeRepositoryProvider).insert(income);
    ref.invalidateSelf();
  }

  Future<void> remove(String id) async {
    await ref.read(incomeRepositoryProvider).delete(id);
    ref.invalidateSelf();
  }
}
