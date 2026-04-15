import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/subscription_provider.dart';
import '../../data/models/subscription_model.dart';
import '../../../../core/providers/settings_provider.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});
  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final subsAsync = ref.watch(subscriptionListProvider);
    final monthlyCostAsync = ref.watch(monthlySubscriptionCostProvider);
    final sym = ref.watch(settingsProvider).currencySymbol;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Subscriptions',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: cs.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            onPressed: () => _showAddSheet(context),
          ),
        ],
      ),
      body: subsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (subs) {
          if (subs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🔄', style: TextStyle(fontSize: 64)),
                  const SizedBox(height: 16),
                  Text('No subscriptions yet',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(color: cs.onSurface)),
                  const SizedBox(height: 8),
                  Text('Track recurring payments like Netflix, Spotify...',
                      style: TextStyle(color: cs.onSurfaceVariant)),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => _showAddSheet(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Subscription'),
                  ),
                ],
              ),
            );
          }

          final active = subs.where((s) => s.isActive).toList();
          final inactive = subs.where((s) => !s.isActive).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Monthly cost header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [cs.primary, cs.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    Text('MONTHLY COST',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5)),
                    const SizedBox(height: 8),
                    Text(
                      '$sym${(monthlyCostAsync.asData?.value ?? 0).toStringAsFixed(0)}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                        '${active.length} active subscription${active.length != 1 ? 's' : ''}',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              if (active.isNotEmpty) ...[
                Text('ACTIVE',
                    style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5)),
                const SizedBox(height: 12),
                ...active.map((s) => _SubCard(sub: s, sym: sym)),
              ],

              if (inactive.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text('INACTIVE',
                    style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5)),
                const SizedBox(height: 12),
                ...inactive.map((s) => _SubCard(sub: s, sym: sym)),
              ],
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
    );
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddSubscriptionSheet(
        onSave: (sub) => ref.read(subscriptionListProvider.notifier).add(sub),
      ),
    );
  }
}

class _SubCard extends ConsumerWidget {
  final SubscriptionModel sub;
  final String sym;
  const _SubCard({required this.sub, required this.sym});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final dueText = sub.nextDueDate != null
        ? DateFormat('MMM d').format(sub.nextDueDate!)
        : 'N/A';

    return Dismissible(
      key: Key(sub.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: cs.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(Icons.delete_outline, color: cs.error),
      ),
      onDismissed: (_) =>
          ref.read(subscriptionListProvider.notifier).remove(sub.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: sub.isDueSoon
                ? Colors.orange.withValues(alpha: 0.5)
                : sub.isOverdue
                    ? cs.error.withValues(alpha: 0.5)
                    : cs.outlineVariant.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Text(sub.icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sub.name,
                      style: TextStyle(
                          color: cs.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(sub.frequency,
                          style: TextStyle(
                              color: cs.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    Text('Due $dueText',
                        style: TextStyle(
                            color: sub.isOverdue
                                ? cs.error
                                : cs.onSurfaceVariant,
                            fontSize: 11)),
                  ]),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('$sym${sub.amount.toStringAsFixed(0)}',
                    style: TextStyle(
                        color: cs.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => ref
                      .read(subscriptionListProvider.notifier)
                      .toggleActive(sub.id, !sub.isActive),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: sub.isActive
                          ? Colors.green.withValues(alpha: 0.1)
                          : cs.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      sub.isActive ? 'Active' : 'Paused',
                      style: TextStyle(
                          color: sub.isActive ? Colors.green : cs.error,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AddSubscriptionSheet extends StatefulWidget {
  final void Function(SubscriptionModel) onSave;
  const _AddSubscriptionSheet({required this.onSave});

  @override
  State<_AddSubscriptionSheet> createState() => _AddSubscriptionSheetState();
}

class _AddSubscriptionSheetState extends State<_AddSubscriptionSheet> {
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  String _frequency = 'monthly';
  String _category = 'Utilities';
  String _icon = '🔄';

  static const _icons = ['🔄', '🎵', '📺', '🎮', '☁️', '📱', '🏋️', '📰', '🎓', '💻'];
  static const _frequencies = ['weekly', 'monthly', 'yearly'];
  static const _categories = [
    'Utilities', 'Entertainment', 'Food', 'Housing', 'Shopping', 'Other'
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (name.isEmpty || amount == null || amount <= 0) return;
    widget.onSave(SubscriptionModel(
      name: name,
      amount: amount,
      frequency: _frequency,
      category: _category,
      startDate: DateTime.now(),
      icon: _icon,
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
                child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                        color: cs.outlineVariant,
                        borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text('New Subscription',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold, color: cs.onSurface)),
            const SizedBox(height: 20),
            // Icon picker
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _icons
                    .map((e) => GestureDetector(
                          onTap: () => setState(() => _icon = e),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _icon == e
                                  ? cs.primaryContainer
                                  : cs.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: _icon == e
                                      ? cs.primary
                                      : cs.outlineVariant),
                            ),
                            child: Text(e, style: const TextStyle(fontSize: 22)),
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              style: TextStyle(color: cs.onSurface),
              decoration: InputDecoration(
                labelText: 'Name (e.g. Netflix)',
                filled: true,
                fillColor: cs.surfaceContainerLowest,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(color: cs.onSurface),
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: '৳ ',
                filled: true,
                fillColor: cs.surfaceContainerLowest,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _frequency,
                  decoration: InputDecoration(
                    labelText: 'Frequency',
                    filled: true,
                    fillColor: cs.surfaceContainerLowest,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  items: _frequencies
                      .map((f) =>
                          DropdownMenuItem(value: f, child: Text(f)))
                      .toList(),
                  onChanged: (v) => setState(() => _frequency = v!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    filled: true,
                    fillColor: cs.surfaceContainerLowest,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  items: _categories
                      .map((c) =>
                          DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => _category = v!),
                ),
              ),
            ]),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check),
                label: const Text('Add Subscription'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
