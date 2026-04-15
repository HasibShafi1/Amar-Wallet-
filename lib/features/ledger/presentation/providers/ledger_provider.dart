import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/ledger_model.dart';
import '../../data/repositories/ledger_repository.dart';

final ledgerRepositoryProvider = Provider((_) => LedgerRepository());

final ledgerListProvider =
    AsyncNotifierProvider<LedgerListNotifier, List<LedgerModel>>(
        LedgerListNotifier.new);

final pendingLentProvider = FutureProvider<double>((ref) async {
  return ref.read(ledgerRepositoryProvider).getPendingLentTotal();
});

final pendingBorrowedProvider = FutureProvider<double>((ref) async {
  return ref.read(ledgerRepositoryProvider).getPendingBorrowedTotal();
});

class LedgerListNotifier extends AsyncNotifier<List<LedgerModel>> {
  @override
  Future<List<LedgerModel>> build() async {
    return ref.read(ledgerRepositoryProvider).getAll();
  }

  Future<void> add(LedgerModel entry) async {
    await ref.read(ledgerRepositoryProvider).insert(entry);
    ref.invalidateSelf();
  }

  Future<void> markPaid(String id) async {
    await ref.read(ledgerRepositoryProvider).markAsPaid(id);
    ref.invalidateSelf();
  }

  Future<void> remove(String id) async {
    await ref.read(ledgerRepositoryProvider).delete(id);
    ref.invalidateSelf();
  }
}
