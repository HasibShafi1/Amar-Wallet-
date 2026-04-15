import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/wallet_provider.dart';
import '../../data/models/wallet_model.dart';

class WalletSelector extends ConsumerWidget {
  const WalletSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletsAsync = ref.watch(walletListProvider);
    final activeId = ref.watch(activeWalletProvider);
    final cs = Theme.of(context).colorScheme;

    return walletsAsync.when(
      data: (wallets) {
        if (wallets.length <= 1) return const SizedBox.shrink();
        return SizedBox(
          height: 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: wallets.length + 1,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              if (index == wallets.length) {
                // Add wallet button
                return GestureDetector(
                  onTap: () => _showAddWalletDialog(context, ref),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: cs.outlineVariant.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, size: 16, color: cs.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text('Add',
                            style: TextStyle(
                                color: cs.onSurfaceVariant, fontSize: 12)),
                      ],
                    ),
                  ),
                );
              }

              final wallet = wallets[index];
              final isActive = wallet.id == activeId;
              return GestureDetector(
                onTap: () =>
                    ref.read(activeWalletProvider.notifier).setWallet(wallet.id),
                onLongPress: wallet.id != 'default'
                    ? () => _showWalletOptions(context, ref, wallet)
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive ? cs.primary : cs.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                                color: cs.primary.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3))
                          ]
                        : [],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(wallet.emoji, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Text(
                        wallet.name,
                        style: TextStyle(
                          color: isActive ? Colors.white : cs.onSurface,
                          fontWeight:
                              isActive ? FontWeight.bold : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const SizedBox(height: 42),
      error: (err, st) => const SizedBox.shrink(),
    );
  }

  void _showAddWalletDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    String emoji = '💼';
    const emojis = ['💼', '🏠', '✈️', '🎮', '📱', '🛍️', '💰', '🎓'];
    final cs = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: cs.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text('New Wallet', style: TextStyle(color: cs.onSurface)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 8,
                children: emojis
                    .map((e) => GestureDetector(
                          onTap: () => setDialogState(() => emoji = e),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: emoji == e
                                  ? cs.primaryContainer
                                  : cs.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: emoji == e
                                      ? cs.primary
                                      : cs.outlineVariant),
                            ),
                            child: Text(e, style: const TextStyle(fontSize: 20)),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                style: TextStyle(color: cs.onSurface),
                decoration: InputDecoration(
                  labelText: 'Wallet name',
                  filled: true,
                  fillColor: cs.surfaceContainerLowest,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                if (nameCtrl.text.trim().isNotEmpty) {
                  ref.read(walletListProvider.notifier).add(
                      WalletModel(name: nameCtrl.text.trim(), emoji: emoji));
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showWalletOptions(
      BuildContext context, WidgetRef ref, WalletModel wallet) {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${wallet.emoji} ${wallet.name}',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            ListTile(
              leading: Icon(Icons.delete_outline_rounded, color: cs.error),
              title: Text('Delete Wallet',
                  style: TextStyle(color: cs.error)),
              subtitle: const Text('Expenses will move to Personal wallet'),
              onTap: () {
                ref.read(walletListProvider.notifier).remove(wallet.id);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }
}
