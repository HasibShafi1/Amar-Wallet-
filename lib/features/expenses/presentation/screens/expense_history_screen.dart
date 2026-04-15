import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/settings_provider.dart';
import '../providers/expense_provider.dart';
import '../widgets/add_expense_bottom_sheet.dart';
import 'edit_expense_screen.dart';

class ExpenseHistoryScreen extends ConsumerStatefulWidget {
  const ExpenseHistoryScreen({super.key});

  @override
  ConsumerState<ExpenseHistoryScreen> createState() => _ExpenseHistoryScreenState();
}

class _ExpenseHistoryScreenState extends ConsumerState<ExpenseHistoryScreen> {
  String _selectedFilter = 'All';
  String _searchQuery = '';
  bool _isSearching = false;
  final _searchCtrl = TextEditingController();

  final List<String> _filters = ['All', 'Food', 'Transport', 'Shopping', 'Groceries', 'Entertainment', 'Housing', 'Utilities', 'Other'];

  final Map<String, IconData> _categoryIcons = {
    'food': Icons.restaurant_rounded,
    'transport': Icons.directions_car_rounded,
    'shopping': Icons.shopping_bag_rounded,
    'groceries': Icons.local_grocery_store_rounded,
    'entertainment': Icons.movie_rounded,
    'housing': Icons.home_rounded,
    'utilities': Icons.electric_bolt_rounded,
    'other': Icons.category_rounded,
  };

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expenseState = ref.watch(expenseListProvider);
    final settings = ref.watch(settingsProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: _isSearching ? 80 : 140.0,
            floating: false,
            pinned: true,
            backgroundColor: cs.surface.withValues(alpha: 0.95),
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 24, bottom: 16, right: 16),
              title: _isSearching
                  ? TextField(
                      controller: _searchCtrl,
                      autofocus: true,
                      style: Theme.of(context).textTheme.titleMedium,
                      decoration: InputDecoration(
                        hintText: 'Search expenses...',
                        border: InputBorder.none,
                        filled: false,
                        hintStyle: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                      ),
                      onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                    )
                  : Text(
                      'Transactions',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [cs.surface, cs.surfaceContainerLow],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _isSearching ? Icons.close : Icons.search_rounded,
                  color: cs.primary,
                ),
                onPressed: () {
                  setState(() {
                    _isSearching = !_isSearching;
                    if (!_isSearching) {
                      _searchQuery = '';
                      _searchCtrl.clear();
                    }
                  });
                },
              ),
              IconButton(
                icon: Icon(Icons.add_circle, color: cs.primary, size: 28),
                onPressed: () => AddExpenseBottomSheet.show(context),
              ),
              const SizedBox(width: 4),
            ],
          ),
          // Category Filter Chips
          SliverToBoxAdapter(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  child: SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _filters.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final filter = _filters[index];
                        final isSelected = filter == _selectedFilter;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedFilter = filter),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? cs.primary : cs.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: isSelected ? [BoxShadow(color: cs.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              filter,
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: isSelected ? Colors.white : cs.onSurfaceVariant,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                // Summary Stats for filtered view
                expenseState.when(
                  data: (expenses) {
                    final filtered = expenses.where((e) {
                      final matchesFilter = _selectedFilter == 'All' || e.category.toLowerCase() == _selectedFilter.toLowerCase();
                      final matchesSearch = _searchQuery.isEmpty || e.description.toLowerCase().contains(_searchQuery);
                      return matchesFilter && matchesSearch;
                    }).toList();
                    final total = filtered.fold(0.0, (s, e) => s + e.amount);
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      child: Row(
                        children: [
                          Text(
                            '${filtered.length} Items',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(color: cs.onSurfaceVariant),
                          ),
                          const Spacer(),
                          Text(
                            'Total: ',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(color: cs.onSurfaceVariant),
                          ),
                          Text(
                            '${settings.currencySymbol}${total.toStringAsFixed(0)}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (err, stack) => Center(child: Text('Error: $err')),
                ),
                const Divider(indent: 24, endIndent: 24, height: 32),
              ],
            ),
          ),
          expenseState.when(
            loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
            error: (err, stack) => const SliverFillRemaining(child: Center(child: Text('Error loading expenses'))),
            data: (expenses) {
              var filtered = expenses.where((e) {
                final matchesFilter = _selectedFilter == 'All' || e.category.toLowerCase() == _selectedFilter.toLowerCase();
                final matchesSearch = _searchQuery.isEmpty ||
                    e.description.toLowerCase().contains(_searchQuery) ||
                    e.category.toLowerCase().contains(_searchQuery) ||
                    e.amount.toString().contains(_searchQuery);
                return matchesFilter && matchesSearch;
              }).toList();

              // Sort by date descending
              filtered.sort((a, b) => b.date.compareTo(a.date));

              if (filtered.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.receipt_long, size: 64, color: cs.outline.withValues(alpha: 0.3)),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty ? 'No results for "$_searchQuery"' : 'No transactions yet',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        if (_searchQuery.isEmpty) ...[
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => AddExpenseBottomSheet.show(context),
                            icon: const Icon(Icons.add),
                            label: const Text('Add first expense'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: cs.primaryContainer,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.only(left: 24, right: 24, bottom: 120),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final exp = filtered[index];
                      bool showDate = true;
                      if (index > 0) {
                        final prev = filtered[index - 1];
                        showDate = exp.date.day != prev.date.day ||
                                   exp.date.month != prev.date.month ||
                                   exp.date.year != prev.date.year;
                      }

                      final iconData = _categoryIcons[exp.category.toLowerCase()] ?? Icons.category_rounded;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (showDate) ...[
                            if (index > 0) const SizedBox(height: 24),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(
                                DateFormat('EEEE, MMM d').format(exp.date),
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: cs.primary.withValues(alpha: 0.7),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
                            ),
                            child: Dismissible(
                              key: Key(exp.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                decoration: BoxDecoration(
                                  color: cs.error.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 24),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.delete_rounded, color: cs.error),
                                    const SizedBox(height: 4),
                                    Text('Delete', style: TextStyle(color: cs.error, fontSize: 11, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                              confirmDismiss: (_) async {
                                return await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Delete Expense?'),
                                    content: Text('This will permanently delete "${exp.description}".'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, true),
                                        child: Text('Delete', style: TextStyle(color: cs.error)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              onDismissed: (_) {
                                ref.read(expenseListProvider.notifier).deleteExpense(exp.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('"${exp.description}" deleted'),
                                    action: SnackBarAction(label: 'OK', onPressed: () {}),
                                  ),
                                );
                              },
                              // Tap to edit
                              child: InkWell(
                                onTap: () => EditExpenseScreen.show(context, exp),
                                borderRadius: BorderRadius.circular(20),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: cs.primary.withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(iconData, color: cs.primary, size: 22),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(exp.description, style: Theme.of(context).textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: cs.primary.withValues(alpha: 0.08),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(exp.category, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.primary)),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  DateFormat('h:mm a').format(exp.date),
                                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                                                ),
                                              ],
                                            ),
                                            if (exp.tags.isNotEmpty) ...[
                                              const SizedBox(height: 6),
                                              Wrap(
                                                spacing: 4,
                                                runSpacing: 4,
                                                children: exp.tags.map((tag) => Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                                  decoration: BoxDecoration(
                                                    color: cs.secondaryContainer.withValues(alpha: 0.5),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text('#$tag', style: TextStyle(color: cs.onSecondaryContainer, fontSize: 9)),
                                                )).toList(),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '${settings.currencySymbol}${exp.amount.toStringAsFixed(2)}',
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              color: cs.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Icon(Icons.chevron_right_rounded, size: 16, color: cs.outline.withValues(alpha: 0.4)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                    childCount: filtered.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
