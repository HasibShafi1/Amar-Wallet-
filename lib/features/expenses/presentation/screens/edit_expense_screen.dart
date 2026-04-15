import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/expense_model.dart';
import '../providers/expense_provider.dart';
import '../widgets/tag_chip_input.dart';

class EditExpenseScreen extends ConsumerStatefulWidget {
  final ExpenseModel expense;
  const EditExpenseScreen({super.key, required this.expense});

  static Future<void> show(BuildContext context, ExpenseModel expense) {
    return Navigator.push(
      context,
      MaterialPageRoute(builder: (ctx) => EditExpenseScreen(expense: expense)),
    );
  }

  @override
  ConsumerState<EditExpenseScreen> createState() => _EditExpenseScreenState();
}

class _EditExpenseScreenState extends ConsumerState<EditExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _descController;
  late String _selectedCategory;
  late DateTime _selectedDate;
  late List<String> _tags;

  final List<String> _categories = [
    'Food', 'Transport', 'Shopping', 'Groceries',
    'Entertainment', 'Housing', 'Utilities', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.expense.amount.toStringAsFixed(2));
    _descController = TextEditingController(text: widget.expense.description);
    _selectedCategory = _validCategory(widget.expense.category);
    _selectedDate = widget.expense.date;
    _tags = List.from(widget.expense.tags);
  }

  String _validCategory(String cat) {
    const valid = ['Food', 'Transport', 'Shopping', 'Groceries', 'Entertainment', 'Housing', 'Utilities', 'Other'];
    return valid.contains(cat) ? cat : 'Other';
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
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

  void _save() {
    if (_formKey.currentState!.validate()) {
      final amount = double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0.0;
      if (amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Amount must be greater than 0')));
        return;
      }
      final updated = widget.expense.copyWith(
        amount: amount,
        description: _descController.text.trim(),
        category: _selectedCategory,
        date: _selectedDate,
        tags: _tags,
      );
      ref.read(expenseListProvider.notifier).updateExpense(updated);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: cs.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Edit Expense', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: cs.primary)),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text('Save', style: TextStyle(color: cs.primaryContainer, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Amount
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(children: [
                  Text(
                    '\$  ',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: cs.primary.withValues(alpha: 0.4), fontWeight: FontWeight.bold,
                    ),
                  ),
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
                      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descController,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: cs.onSurface),
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: TextStyle(color: cs.onSurfaceVariant),
                  filled: true,
                  fillColor: cs.surfaceContainerLow,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  prefixIcon: Icon(Icons.notes_rounded, color: cs.primary),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Category
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(children: [
                  Icon(Icons.category_rounded, color: cs.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCategory,
                        isExpanded: true,
                        icon: Icon(Icons.keyboard_arrow_down, color: cs.primary),
                        dropdownColor: cs.surfaceContainerLow,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: cs.onSurface),
                        items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (v) { if (v != null) setState(() => _selectedCategory = v); },
                      ),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 16),

              // Tags
              TagChipInput(
                initialTags: _tags,
                onTagsChanged: (tags) => setState(() => _tags = tags),
              ),
              const SizedBox(height: 16),

              // Date picker
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(children: [
                    Icon(Icons.calendar_today_rounded, color: cs.primary),
                    const SizedBox(width: 12),
                    Text(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: cs.onSurface),
                    ),
                    const Spacer(),
                    Text('Change', style: TextStyle(color: cs.primary, fontSize: 12)),
                  ]),
                ),
              ),
              const SizedBox(height: 40),

              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primaryContainer,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('Save Changes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
