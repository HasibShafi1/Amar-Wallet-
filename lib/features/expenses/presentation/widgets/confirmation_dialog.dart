import 'package:flutter/material.dart';
import '../../../../core/constants/theme.dart';
import '../../data/models/expense_model.dart';
import 'package:intl/intl.dart';

class ConfirmationDialog extends StatefulWidget {
  final List<ExpenseModel> parsedExpenses;
  final Function(List<ExpenseModel>) onConfirm;

  const ConfirmationDialog({
    super.key,
    required this.parsedExpenses,
    required this.onConfirm,
  });

  @override
  State<ConfirmationDialog> createState() => _ConfirmationDialogState();
}

class _ConfirmationDialogState extends State<ConfirmationDialog> {
  late List<ExpenseModel> _editableExpenses;

  @override
  void initState() {
    super.initState();
    _editableExpenses = List.from(widget.parsedExpenses);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: AmarTheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Confirm Expenses', style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 16),
            if (_editableExpenses.isEmpty)
              const Text('No expenses detected.')
            else
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _editableExpenses.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final exp = _editableExpenses[index];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AmarTheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextFormField(
                                  initialValue: exp.description,
                                  style: Theme.of(context).textTheme.titleMedium,
                                  decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                                  onChanged: (val) {
                                    _editableExpenses[index] = exp.copyWith(description: val);
                                  },
                                ),
                                const SizedBox(height: 4),
                                TextFormField(
                                  initialValue: exp.category,
                                  style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AmarTheme.secondary),
                                  decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                                  onChanged: (val) {
                                    _editableExpenses[index] = exp.copyWith(category: val);
                                  },
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 80,
                            child: TextFormField(
                              initialValue: exp.amount.toString(),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: Theme.of(context).textTheme.titleLarge,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                prefixText: NumberFormat.simpleCurrency().currencySymbol,
                              ),
                              onChanged: (val) {
                                final parsed = double.tryParse(val);
                                if (parsed != null) {
                                  _editableExpenses[index] = exp.copyWith(amount: parsed);
                                }
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            onPressed: () {
                              setState(() {
                                _editableExpenses.removeAt(index);
                              });
                            },
                          )
                        ],
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: TextStyle(color: AmarTheme.onSurfaceVariant)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AmarTheme.primaryContainer,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  onPressed: _editableExpenses.isEmpty ? null : () {
                    widget.onConfirm(_editableExpenses);
                    Navigator.pop(context);
                  },
                  child: const Text('Confirm'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
