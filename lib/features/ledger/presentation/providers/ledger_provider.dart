import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/ledger_model.dart';
import '../../data/repositories/ledger_repository.dart';

final ledgerRepositoryProvider = Provider((_) => LedgerRepository());

final ledgerListProvider =
    AsyncNotifierProvider<LedgerListNotifier, List<LedgerModel>>(
        LedgerListNotifier.new);

final pendingLentProvider = Provider<double>((ref) {
  final entries = ref.watch(ledgerListProvider).value ?? [];
  return entries
      .where((e) => e.type == 'lent' && e.isPaid == false)
      .fold(0.0, (sum, e) => sum + e.amount);
});

final pendingBorrowedProvider = Provider<double>((ref) {
  final entries = ref.watch(ledgerListProvider).value ?? [];
  return entries
      .where((e) => e.type == 'borrowed' && e.isPaid == false)
      .fold(0.0, (sum, e) => sum + e.amount);
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
