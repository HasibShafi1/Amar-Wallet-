import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/expense_model.dart';
import '../../data/models/tag_model.dart';
import '../../data/repositories/expense_repository.dart';
import '../../../wallets/presentation/providers/wallet_provider.dart';

final expenseListProvider = AsyncNotifierProvider<ExpenseListNotifier, List<ExpenseModel>>(() {
  return ExpenseListNotifier();
});

/// All tags in the database
final allTagsProvider = FutureProvider<List<TagModel>>((ref) async {
  // Re-fetch when expenses change (tags may be added)
  ref.watch(expenseListProvider);
  return ref.read(expenseRepositoryProvider).getAllTags();
});

class ExpenseListNotifier extends AsyncNotifier<List<ExpenseModel>> {
  @override
  FutureOr<List<ExpenseModel>> build() async {
    return _fetchExpenses();
  }

  Future<List<ExpenseModel>> _fetchExpenses() async {
    final repository = ref.read(expenseRepositoryProvider);
    final walletId = ref.read(activeWalletProvider);
    return await repository.getExpenses(walletId: walletId);
  }

  Future<void> addExpense(ExpenseModel expense) async {
    final repository = ref.read(expenseRepositoryProvider);
    // Assign active wallet if not set
    final walletId = ref.read(activeWalletProvider);
    final exp = expense.walletId == 'default' && walletId != 'default'
        ? expense.copyWith(walletId: walletId)
        : expense;
    await repository.addExpense(exp);
    state = AsyncValue.data(await _fetchExpenses());
  }

  Future<void> addMultiple(List<ExpenseModel> expenses) async {
    final repository = ref.read(expenseRepositoryProvider);
    final walletId = ref.read(activeWalletProvider);
    for (final exp in expenses) {
      final e = exp.walletId == 'default' && walletId != 'default'
          ? exp.copyWith(walletId: walletId)
          : exp;
      await repository.addExpense(e);
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
