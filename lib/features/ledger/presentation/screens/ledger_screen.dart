import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/models/ledger_model.dart';
import '../providers/ledger_provider.dart';

class LedgerScreen extends ConsumerStatefulWidget {
  const LedgerScreen({super.key});
  @override
  ConsumerState<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends ConsumerState<LedgerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final all = ref.watch(ledgerListProvider);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Ledger', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: cs.surface,
        elevation: 0,
        bottom: TabBar(
          controller: _tab,
          indicatorColor: cs.primary,
          labelColor: cs.primary,
          unselectedLabelColor: cs.onSurfaceVariant,
          tabs: const [
            Tab(icon: Icon(Icons.arrow_upward_rounded), text: 'You Lent'),
            Tab(icon: Icon(Icons.arrow_downward_rounded), text: 'You Borrowed'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            onPressed: () => _showAddDialog(context),
          ),
        ],
      ),
      body: all.when(
        data: (entries) {
          final lent = entries.where((e) => e.type == 'lent').toList();
          final borrowed = entries.where((e) => e.type == 'borrowed').toList();
          return TabBarView(
            controller: _tab,
            children: [
              _LedgerList(entries: lent, emptyLabel: 'No lending records yet', color: Colors.green),
              _LedgerList(entries: borrowed, emptyLabel: 'No borrowing records yet', color: cs.error),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Entry'),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddLedgerSheet(onAdd: (entry) {
        ref.read(ledgerListProvider.notifier).add(entry);
      }),
    );
  }
}

class _LedgerList extends ConsumerWidget {
  final List<LedgerModel> entries;
  final String emptyLabel;
  final Color color;

  const _LedgerList({required this.entries, required this.emptyLabel, required this.color});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final pending = entries.where((e) => !e.isPaid).toList();
    final paid = entries.where((e) => e.isPaid).toList();
    final total = pending.fold(0.0, (s, e) => s + e.amount);

    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.handshake_outlined, size: 64, color: cs.outlineVariant),
            const SizedBox(height: 12),
            Text(emptyLabel, style: TextStyle(color: cs.onSurfaceVariant)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.account_balance_wallet_rounded, color: color),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Pending Total',
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
                Text(
                  NumberFormat.currency(symbol: '৳', decimalDigits: 0)
                      .format(total),
                  style: TextStyle(
                      color: color,
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                ),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (pending.isNotEmpty) ...[
          Text('PENDING',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          ...pending.map((e) => _EntryCard(entry: e, accentColor: color)),
          const SizedBox(height: 16),
        ],

        if (paid.isNotEmpty) ...[
          Text('PAID',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          ...paid.map((e) => _EntryCard(entry: e, accentColor: cs.outlineVariant)),
        ],
      ],
    );
  }
}

class _EntryCard extends ConsumerWidget {
  final LedgerModel entry;
  final Color accentColor;
  const _EntryCard({required this.entry, required this.accentColor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: cs.error.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.delete_outline, color: cs.error),
      ),
      onDismissed: (_) =>
          ref.read(ledgerListProvider.notifier).remove(entry.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: accentColor.withValues(alpha: 0.15),
            child: Text(entry.person[0].toUpperCase(),
                style: TextStyle(color: accentColor, fontWeight: FontWeight.bold)),
          ),
          title: Text(entry.person,
              style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.bold)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (entry.note.isNotEmpty)
                Text(entry.note, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
              Text(DateFormat('d MMM y').format(entry.date),
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11)),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '৳${entry.amount.toStringAsFixed(0)}',
                style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
              if (!entry.isPaid)
                GestureDetector(
                  onTap: () =>
                      ref.read(ledgerListProvider.notifier).markPaid(entry.id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Mark Paid',
                        style: TextStyle(color: Colors.green, fontSize: 11)),
                  ),
                )
              else
                const Text('Paid ✓',
                    style: TextStyle(color: Colors.green, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddLedgerSheet extends StatefulWidget {
  final void Function(LedgerModel) onAdd;
  const _AddLedgerSheet({required this.onAdd});

  @override
  State<_AddLedgerSheet> createState() => _AddLedgerSheetState();
}

class _AddLedgerSheetState extends State<_AddLedgerSheet> {
  final _personCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String _type = 'lent';

  @override
  void dispose() {
    _personCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final person = _personCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (person.isEmpty || amount == null || amount <= 0) return;
    widget.onAdd(LedgerModel(
      type: _type,
      person: person,
      amount: amount,
      note: _noteCtrl.text.trim(),
      date: DateTime.now(),
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
                width: 44, height: 4,
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Add Ledger Entry',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold, color: cs.onSurface)),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: _TypeButton(
                  label: 'I Lent',
                  icon: Icons.arrow_upward_rounded,
                  color: Colors.green,
                  selected: _type == 'lent',
                  onTap: () => setState(() => _type = 'lent'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TypeButton(
                  label: 'I Borrowed',
                  icon: Icons.arrow_downward_rounded,
                  color: cs.error,
                  selected: _type == 'borrowed',
                  onTap: () => setState(() => _type = 'borrowed'),
                ),
              ),
            ]),
            const SizedBox(height: 16),
            TextField(
              controller: _personCtrl,
              style: TextStyle(color: cs.onSurface),
              decoration: InputDecoration(
                labelText: 'Person name',
                prefixIcon: Icon(Icons.person_outline, color: cs.primary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                filled: true,
                fillColor: cs.surfaceContainerLowest,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(color: cs.onSurface),
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixIcon: Icon(Icons.attach_money, color: cs.primary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                filled: true,
                fillColor: cs.surfaceContainerLowest,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteCtrl,
              style: TextStyle(color: cs.onSurface),
              decoration: InputDecoration(
                labelText: 'Note (optional)',
                prefixIcon: Icon(Icons.notes, color: cs.primary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                filled: true,
                fillColor: cs.surfaceContainerLowest,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check),
                label: const Text('Save Entry'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _TypeButton({required this.label, required this.icon, required this.color, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : Theme.of(context).colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? color : Theme.of(context).colorScheme.outlineVariant),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: selected ? color : Theme.of(context).colorScheme.onSurfaceVariant, size: 18),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: selected ? color : Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
        ]),
      ),
    );
  }
}
