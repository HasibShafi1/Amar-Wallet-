import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/wallet_model.dart';
import '../../data/repositories/wallet_repository.dart';

final walletRepositoryProvider = Provider((_) => WalletRepository());

final walletListProvider =
    AsyncNotifierProvider<WalletListNotifier, List<WalletModel>>(
        WalletListNotifier.new);

final activeWalletProvider = NotifierProvider<ActiveWalletNotifier, String>(ActiveWalletNotifier.new);

class ActiveWalletNotifier extends Notifier<String> {
  @override
  String build() => 'default';

  void setWallet(String id) => state = id;
}

class WalletListNotifier extends AsyncNotifier<List<WalletModel>> {
  @override
  Future<List<WalletModel>> build() async {
    return ref.read(walletRepositoryProvider).getAll();
  }

  Future<void> add(WalletModel wallet) async {
    await ref.read(walletRepositoryProvider).insert(wallet);
    ref.invalidateSelf();
  }

  Future<void> updateWallet(WalletModel wallet) async {
    await ref.read(walletRepositoryProvider).update(wallet);
    ref.invalidateSelf();
  }

  Future<void> remove(String id) async {
    await ref.read(walletRepositoryProvider).delete(id);
    // If deleted wallet was active, switch to default
    if (ref.read(activeWalletProvider) == id) {
      ref.read(activeWalletProvider.notifier).setWallet('default');
    }
    ref.invalidateSelf();
  }
}
