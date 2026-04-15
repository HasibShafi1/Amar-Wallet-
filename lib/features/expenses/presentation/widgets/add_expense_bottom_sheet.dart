import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../data/models/expense_model.dart';
import '../providers/expense_provider.dart';
import 'tag_chip_input.dart';

class AddExpenseBottomSheet extends ConsumerStatefulWidget {
  const AddExpenseBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddExpenseBottomSheet(),
    );
  }

  @override
  ConsumerState<AddExpenseBottomSheet> createState() => _AddExpenseBottomSheetState();
}

class _AddExpenseBottomSheetState extends ConsumerState<AddExpenseBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = 'Other';
  List<String> _tags = [];

  final List<String> _categories = [
    'Food', 'Transport', 'Shopping', 'Groceries',
    'Entertainment', 'Housing', 'Utilities', 'Other'
  ];

  void _saveExpense() {
    if (_formKey.currentState!.validate()) {
      final amount = double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0.0;
      if (amount <= 0) return;

      ref.read(expenseListProvider.notifier).addExpense(ExpenseModel(
        amount: amount,
        category: _selectedCategory,
        description: _descController.text.trim(),
        date: _selectedDate,
        tags: _tags,
      ));
      Navigator.pop(context);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final cs = Theme.of(context).colorScheme;
    final settings = ref.watch(settingsProvider);

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, bottomInset + 32),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 48, height: 5,
                  decoration: BoxDecoration(
                    color: cs.outline.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Add Expense',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: cs.primary, fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),

              // Amount
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(children: [
                  Text(
                    settings.currencySymbol,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: cs.primary.withValues(alpha: 0.4), fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: cs.primary),
                      decoration: InputDecoration(
                        hintText: '0.00',
                        border: InputBorder.none,
                        filled: false,
                        hintStyle: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? 'Enter amount' : null,
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 14),

              // Description
              TextFormField(
                controller: _descController,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: cs.onSurface),
                decoration: InputDecoration(
                  hintText: 'What was this for?',
                  filled: true,
                  fillColor: cs.surfaceContainerLow,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  prefixIcon: Icon(Icons.notes_rounded, color: cs.primary, size: 20),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Enter description' : null,
              ),
              const SizedBox(height: 14),

              // Category
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(children: [
                  Icon(Icons.category_rounded, color: cs.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCategory,
                        isExpanded: true,
                        icon: Icon(Icons.keyboard_arrow_down, color: cs.primary),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: cs.onSurface),
                        dropdownColor: cs.surfaceContainerLow,
                        items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (v) { if (v != null) setState(() => _selectedCategory = v); },
                      ),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 14),

              // Tags
              TagChipInput(
                initialTags: _tags,
                onTagsChanged: (tags) => setState(() => _tags = tags),
              ),
              const SizedBox(height: 14),

              // Date
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(children: [
                    Icon(Icons.calendar_today_rounded, color: cs.primary, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: cs.onSurface),
                    ),
                    const Spacer(),
                    Text('Change', style: TextStyle(color: cs.primary, fontSize: 12)),
                  ]),
                ),
              ),
              const SizedBox(height: 28),

              ElevatedButton(
                onPressed: _saveExpense,
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primaryContainer,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('Save Expense', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
