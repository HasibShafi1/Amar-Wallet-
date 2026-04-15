import 'package:flutter/material.dart';
import '../../../../core/utils/category_engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/expense_model.dart';
import 'package:intl/intl.dart';

class ConfirmationDialog extends ConsumerStatefulWidget {
  final List<ExpenseModel> parsedExpenses;
  final Function(List<ExpenseModel>) onConfirm;

  const ConfirmationDialog({
    super.key,
    required this.parsedExpenses,
    required this.onConfirm,
  });

  @override
  ConsumerState<ConfirmationDialog> createState() => _ConfirmationDialogState();
}

class _ConfirmationDialogState extends ConsumerState<ConfirmationDialog> {
  late List<ExpenseModel> _editableExpenses;

  @override
  void initState() {
    super.initState();
    _editableExpenses = List.from(widget.parsedExpenses);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: cs.surface,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.check_circle_outline_rounded, color: cs.primary, size: 28),
              const SizedBox(width: 12),
              Text('Confirm Expenses', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: cs.primary)),
            ]),
            const SizedBox(height: 8),
            Text(
              '${_editableExpenses.length} item(s) detected. Review before saving.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            if (_editableExpenses.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text('No expenses detected.', style: Theme.of(context).textTheme.bodyLarge),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _editableExpenses.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final exp = _editableExpenses[index];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: cs.outline.withValues(alpha: 0.15)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextFormField(
                                  initialValue: exp.description,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: cs.onSurface),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    filled: false,
                                    isDense: true,
                                    hintText: 'Description',
                                    hintStyle: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                                  ),
                                  onChanged: (val) => _editableExpenses[index] = exp.copyWith(description: val),
                                ),
                                const SizedBox(height: 2),
                                // Category dropdown inline
                                DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _validCategory(exp.category),
                                    isDense: true,
                                    icon: Icon(Icons.keyboard_arrow_down, color: cs.primary, size: 16),
                                    dropdownColor: cs.surfaceContainerLow,
                                    style: Theme.of(context).textTheme.labelMedium?.copyWith(color: cs.secondary),
                                    items: ['Food', 'Transport', 'Shopping', 'Groceries', 'Entertainment', 'Housing', 'Utilities', 'Other']
                                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                                        .toList(),
                                    onChanged: (val) {
                                      if (val != null) setState(() => _editableExpenses[index] = exp.copyWith(category: val));
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 90,
                            child: TextFormField(
                              initialValue: exp.amount.toStringAsFixed(2),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: cs.primary, fontWeight: FontWeight.bold),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                filled: false,
                                isDense: true,
                                prefixText: '${NumberFormat.simpleCurrency().currencySymbol} ',
                                prefixStyle: TextStyle(color: cs.primary.withValues(alpha: 0.5)),
                              ),
                              onChanged: (val) {
                                final parsed = double.tryParse(val.replaceAll(',', ''));
                                if (parsed != null) setState(() => _editableExpenses[index] = exp.copyWith(amount: parsed));
                              },
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline_rounded, color: cs.error),
                            onPressed: () => setState(() => _editableExpenses.removeAt(index)),
                          )
                        ],
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Discard', style: TextStyle(color: cs.onSurfaceVariant)),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.save_rounded, size: 18),
                  label: Text('Save ${_editableExpenses.length} item(s)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primaryContainer,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  onPressed: _editableExpenses.isEmpty ? null : () async {
                    final navigator = Navigator.of(context);
                    // Learn user category preferences for each item
                    for (final e in _editableExpenses) {
                      await CategoryEngine.instance.saveOverride(e.description, e.category);
                    }
                    widget.onConfirm(_editableExpenses);
                    navigator.pop();
                  },
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  String _validCategory(String cat) {
    const valid = ['Food', 'Transport', 'Shopping', 'Groceries', 'Entertainment', 'Housing', 'Utilities', 'Other'];
    return valid.contains(cat) ? cat : 'Other';
  }
}
