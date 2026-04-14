import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/expense_model.dart';
import '../../data/repositories/expense_repository.dart';

final expenseListProvider = AsyncNotifierProvider<ExpenseListNotifier, List<ExpenseModel>>(() {
  return ExpenseListNotifier();
});

class ExpenseListNotifier extends AsyncNotifier<List<ExpenseModel>> {
  @override
  FutureOr<List<ExpenseModel>> build() async {
    return _fetchExpenses();
  }

  Future<List<ExpenseModel>> _fetchExpenses() async {
    final repository = ref.read(expenseRepositoryProvider);
    return await repository.getExpenses();
  }

  Future<void> addExpense(ExpenseModel expense) async {
    final repository = ref.read(expenseRepositoryProvider);
    await repository.addExpense(expense);
    state = AsyncValue.data(await _fetchExpenses());
  }

  Future<void> addMultiple(List<ExpenseModel> expenses) async {
    final repository = ref.read(expenseRepositoryProvider);
    for (final exp in expenses) {
        await repository.addExpense(exp);
    }
    state = AsyncValue.data(await _fetchExpenses());
  }

  Future<void> updateExpense(ExpenseModel expense) async {
    final repository = ref.read(expenseRepositoryProvider);
    await repository.updateExpense(expense);
    state = AsyncValue.data(await _fetchExpenses());
  }

  Future<void> deleteExpense(String id) async {
    final repository = ref.read(expenseRepositoryProvider);
    await repository.deleteExpense(id);
    state = AsyncValue.data(await _fetchExpenses());
  }
}
