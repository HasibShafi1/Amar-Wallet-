import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/subscription_model.dart';
import '../../data/repositories/subscription_repository.dart';

final subscriptionRepositoryProvider =
    Provider((_) => SubscriptionRepository());

final subscriptionListProvider = AsyncNotifierProvider<
    SubscriptionListNotifier, List<SubscriptionModel>>(
    SubscriptionListNotifier.new);

final monthlySubscriptionCostProvider = FutureProvider<double>((ref) async {
  final subs = await ref.watch(subscriptionListProvider.future);
  return subs
      .where((s) => s.isActive)
      .fold<double>(0.0, (sum, s) => sum + s.monthlyCost);
});

final dueSoonProvider = FutureProvider<List<SubscriptionModel>>((ref) async {
  final subs = await ref.watch(subscriptionListProvider.future);
  return subs.where((s) => s.isActive && s.isDueSoon).toList();
});

class SubscriptionListNotifier
    extends AsyncNotifier<List<SubscriptionModel>> {
  @override
  Future<List<SubscriptionModel>> build() async {
    return ref.read(subscriptionRepositoryProvider).getAll();
  }

  Future<void> add(SubscriptionModel sub) async {
    await ref.read(subscriptionRepositoryProvider).insert(sub);
    ref.invalidateSelf();
  }

  Future<void> updateSubscription(SubscriptionModel sub) async {
    await ref.read(subscriptionRepositoryProvider).update(sub);
    ref.invalidateSelf();
  }

  Future<void> toggleActive(String id, bool active) async {
    await ref.read(subscriptionRepositoryProvider).toggleActive(id, active);
    ref.invalidateSelf();
  }

  Future<void> remove(String id) async {
    await ref.read(subscriptionRepositoryProvider).delete(id);
    ref.invalidateSelf();
  }
}
