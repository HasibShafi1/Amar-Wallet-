import 'dart:ui' show ImageFilter;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/providers/settings_provider.dart';
import '../../../expenses/presentation/providers/expense_provider.dart';
import '../../../expenses/presentation/widgets/add_expense_bottom_sheet.dart';
import '../../../income/presentation/providers/income_provider.dart';
import '../../../income/presentation/widgets/add_income_bottom_sheet.dart';
import '../../../ledger/presentation/providers/ledger_provider.dart';
import '../../../ledger/presentation/screens/ledger_screen.dart';
import '../../../goals/data/models/goal_model.dart';
import '../../../goals/presentation/providers/goal_provider.dart';
import '../../../goals/presentation/screens/goals_screen.dart';
import '../../../budget/presentation/providers/budget_provider.dart';
import '../../../subscriptions/presentation/providers/subscription_provider.dart';
import '../../../subscriptions/presentation/screens/subscription_screen.dart';
import '../../../wallets/presentation/widgets/wallet_selector.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  Future<void> _setGoal(BuildContext context, WidgetRef ref, double current, String sym) async {
    final ctrl = TextEditingController(text: current.toStringAsFixed(0));
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Daily Goal'),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            prefixText: '$sym ',
            hintText: '200',
            filled: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, double.tryParse(ctrl.text)),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null && result > 0) {
      ref.read(settingsProvider.notifier).setDailyGoal(result);
    }
  }

  static const List<Color> _pieColors = [
    Color(0xFF004D43),
    Color(0xFF3B6663),
    Color(0xFF00897B),
    Color(0xFF735C00),
    Color(0xFFA0522D),
    Color(0xFF6A4FCA),
    Color(0xFFE76F51),
    Color(0xFF2A9D8F),
  ];

  @override
  Widget build(BuildContext context) {
    final expenseState = ref.watch(expenseListProvider);
    final totalIncomeAsync = ref.watch(totalIncomeProvider);
    final lentAsync = ref.watch(pendingLentProvider);
    final borrowedAsync = ref.watch(pendingBorrowedProvider);
    final goalsAsync = ref.watch(goalListProvider);
    final budgetsAsync = ref.watch(budgetMapProvider);

    final settings = ref.watch(settingsProvider);
    final cs = Theme.of(context).colorScheme;
    final sym = settings.currencySymbol;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface.withValues(alpha: 0.85),
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(color: Colors.transparent),
          ),
        ),
        elevation: 0,
        title: Row(children: [
          CircleAvatar(
            backgroundColor: cs.secondaryContainer,
            child: Text(
              settings.userAvatar,
              style: const TextStyle(fontSize: 20),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('AmarWallet',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w800,
                      )),
              if (settings.userName.isNotEmpty)
                Text(settings.userName,
                    style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 11)),
            ],
          ),
        ]),
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle, color: cs.primary, size: 28),
            onPressed: () => AddExpenseBottomSheet.show(context),
          ),
          IconButton(
            icon: Icon(Icons.savings_rounded, color: cs.primary),
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const AddIncomeBottomSheet(),
            ),
          ),
        ],
      ),
      body: expenseState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Error: $err')),
        data: (expenses) {
          final now = DateTime.now();
          final totalIncome = totalIncomeAsync.asData?.value ?? 0.0;
          final totalSpent = expenses.fold(0.0, (s, e) => s + e.amount);
          final balance = totalIncome - totalSpent;

          final monthlyExpenses = expenses
              .where((e) => e.date.year == now.year && e.date.month == now.month)
              .toList();
          final totalThisMonth =
              monthlyExpenses.fold(0.0, (s, e) => s + e.amount);
          final dailyGoal = settings.dailyGoal;

          final dailyExpenses =
              monthlyExpenses.where((e) => e.date.day == now.day).toList();
          final dailySpent = dailyExpenses.fold(0.0, (s, e) => s + e.amount);
          final remainingDaily = dailyGoal - dailySpent;

          // Category breakdown
          final categoryTotals = <String, double>{};
          for (var e in monthlyExpenses) {
            categoryTotals[e.category] =
                (categoryTotals[e.category] ?? 0.0) + e.amount;
          }
          final sortedCategories = categoryTotals.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          // Last 7 days chart
          final last7 = List.generate(7, (i) {
            final day = now.subtract(Duration(days: 6 - i));
            final total = expenses
                .where((e) =>
                    e.date.year == day.year &&
                    e.date.month == day.month &&
                    e.date.day == day.day)
                .fold(0.0, (s, e) => s + e.amount);
            return _DayData(day: day, total: total);
          });

          return SingleChildScrollView(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + kToolbarHeight + 16,
              left: 20,
              right: 20,
              bottom: 140,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Wallet Selector ───────────────────────────────────
                const WalletSelector(),
                const SizedBox(height: 16),
                // ── Balance Card ──────────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    gradient: LinearGradient(
                      colors: [cs.primary, cs.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: cs.primary.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('AVAILABLE BALANCE',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5)),
                      const SizedBox(height: 8),
                      Text(
                        NumberFormat.currency(symbol: sym, decimalDigits: 0)
                            .format(balance),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: _MiniStat(
                              label: 'Income',
                              value: totalIncome,
                              sym: sym,
                              icon: Icons.south_west_rounded,
                              iconColor: Colors.greenAccent,
                            ),
                          ),
                          Container(
                              width: 1,
                              height: 30,
                              color: Colors.white.withValues(alpha: 0.2)),
                          Expanded(
                            child: _MiniStat(
                              label: 'Expenses',
                              value: totalSpent,
                              sym: sym,
                              icon: Icons.north_east_rounded,
                              iconColor: Colors.redAccent,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Goals Strip ───────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Goals',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold, color: cs.primary)),
                    TextButton(
                      onPressed: () => Navigator.push(
                          context, MaterialPageRoute(builder: (_) => const GoalsScreen())),
                      child: const Text('View All'),
                    ),
                  ],
                ),
                goalsAsync.when(
                  data: (goals) {
                    if (goals.isEmpty) return const SizedBox();
                    return SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: goals.length,
                        itemBuilder: (ctx, i) => _GoalMiniCard(goal: goals[i], sym: sym),
                      ),
                    );
                  },
                  loading: () => const SizedBox(height: 120),
                  error: (e, s) => const SizedBox(),
                ),
                const SizedBox(height: 12),

                // ── Daily Card ────────────────────────────────────────────
                GestureDetector(
                  onTap: () => _setGoal(context, ref, dailyGoal, sym),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('DAILY SPENDING',
                                style: TextStyle(
                                    color: cs.onSurfaceVariant,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2)),
                            Icon(Icons.edit_note_rounded,
                                color: cs.primary, size: 18),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text(
                              '$sym${dailySpent.toStringAsFixed(0)}',
                              style: TextStyle(
                                  color: cs.onSurface,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold),
                            ),
                            Text(' / $sym${dailyGoal.toStringAsFixed(0)}',
                                style: TextStyle(
                                    color: cs.onSurfaceVariant, fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: (dailySpent / dailyGoal).clamp(0.0, 1.0),
                            minHeight: 10,
                            backgroundColor: cs.surfaceContainerLowest,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              dailySpent > dailyGoal ? cs.error : cs.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          remainingDaily >= 0
                              ? '$sym${remainingDaily.toStringAsFixed(0)} more until your limit'
                              : '৳${(-remainingDaily).toStringAsFixed(0)} above daily limit!',
                          style: TextStyle(
                              color: remainingDaily >= 0
                                  ? cs.onSurfaceVariant
                                  : cs.error,
                              fontSize: 12,
                              fontWeight:
                                  remainingDaily < 0 ? FontWeight.bold : null),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Lending Summary Card ──────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _SummaryActionCard(
                        label: 'Lent',
                        icon: Icons.arrow_upward_rounded,
                        color: Colors.green,
                        value: lentAsync.asData?.value ?? 0,
                        sym: sym,
                        onTap: () => Navigator.push(
                            context, MaterialPageRoute(builder: (_) => const LedgerScreen())),
                        cs: cs,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryActionCard(
                        label: 'Borrowed',
                        icon: Icons.arrow_downward_rounded,
                        color: cs.error,
                        value: borrowedAsync.asData?.value ?? 0,
                        sym: sym,
                        onTap: () => Navigator.push(
                            context, MaterialPageRoute(builder: (_) => const LedgerScreen())),
                        cs: cs,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Active Budgets ────────────────────────────────────────
                budgetsAsync.when(
                  data: (budgets) {
                    if (budgets.isEmpty) return const SizedBox();
                    final budgetsWithSpending = budgets.entries.where((entry) {
                      return categoryTotals.containsKey(entry.key);
                    }).toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Monthly Budgets',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold, color: cs.primary)),
                        const SizedBox(height: 16),
                        if (budgetsWithSpending.isEmpty)
                           Padding(
                             padding: const EdgeInsets.only(bottom: 24.0),
                             child: Text('No spending recorded for your budgeted categories yet.', 
                                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
                           )
                        else
                          ...budgetsWithSpending.map((entry) {
                            final spent = categoryTotals[entry.key] ?? 0.0;
                            final limit = entry.value.monthlyLimit;
                            final pct = (spent / limit).clamp(0.0, 1.0);
                            final color = pct > 0.9 ? cs.error : (pct > 0.7 ? Colors.orange : cs.primary);

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      Text('$sym${spent.toStringAsFixed(0)} / $sym${limit.toStringAsFixed(0)}',
                                          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: pct,
                                      minHeight: 6,
                                      backgroundColor: cs.surfaceContainerLowest,
                                      valueColor: AlwaysStoppedAnimation<Color>(color),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        const SizedBox(height: 12),
                      ],
                    );
                  },
                  loading: () => const SizedBox(),
                  error: (e, s) => const SizedBox(),
                ),

                // ── Subscriptions Card ────────────────────────────────────
                Builder(builder: (_) {
                  final monthlyCost = ref.watch(monthlySubscriptionCostProvider);
                  final dueSoon = ref.watch(dueSoonProvider);
                  return GestureDetector(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const SubscriptionScreen())),
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
                      ),
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: cs.tertiary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.autorenew_rounded, color: cs.tertiary, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Subscriptions', style: TextStyle(
                                  color: cs.onSurface, fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(height: 2),
                              Text(
                                monthlyCost.when(
                                  data: (cost) => '$sym${cost.toStringAsFixed(0)}/mo',
                                  loading: () => '...',
                                  error: (err, st) => '--',
                                ),
                                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        if (dueSoon.asData?.value.isNotEmpty == true)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${dueSoon.asData?.value.length ?? 0} due soon',
                              style: const TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        const SizedBox(width: 6),
                        Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant, size: 20),
                      ]),
                    ),
                  );
                }),

                // ── 7-Day Chart ───────────────────────────────────────────
                if (last7.any((d) => d.total > 0)) ...[
                  Text('Last 7 Days',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold, color: cs.primary)),
                  const SizedBox(height: 16),
                  Container(
                    height: 180,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: BarChart(BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: (last7.map((d) => d.total).reduce((a, b) => a > b ? a : b) * 1.5).clamp(10, 1000000),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (v, m) {
                            if (v.toInt() >= last7.length) return const SizedBox();
                            return Text(DateFormat('E').format(last7[v.toInt()].day),
                              style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant));
                          },
                        )),
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      barGroups: List.generate(last7.length, (i) {
                        return BarChartGroupData(x: i, barRods: [
                          BarChartRodData(
                            toY: last7[i].total,
                            color: last7[i].day.day == now.day ? cs.primary : cs.primary.withValues(alpha: 0.3),
                            width: 14,
                            borderRadius: BorderRadius.circular(4),
                          )
                        ]);
                      }),
                    )),
                  ),
                  const SizedBox(height: 24),
                ],

                // ── Pie Chart ─────────────────────────────────────────────
                if (sortedCategories.isNotEmpty) ...[
                  Text('Spending Distribution',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold, color: cs.primary)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Column(children: [
                      SizedBox(
                        height: 180,
                        child: PieChart(PieChartData(
                          sectionsSpace: 4,
                          centerSpaceRadius: 40,
                          sections: List.generate(sortedCategories.length, (i) {
                            return PieChartSectionData(
                              color: _pieColors[i % _pieColors.length],
                              value: sortedCategories[i].value,
                              title: '${(sortedCategories[i].value / totalThisMonth * 100).toInt()}%',
                              radius: 50,
                              titleStyle: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12),
                            );
                          }),
                        )),
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: List.generate(sortedCategories.length, (i) {
                          return Row(mainAxisSize: MainAxisSize.min, children: [
                            Container(width: 12, height: 12, decoration: BoxDecoration(color: _pieColors[i % _pieColors.length], borderRadius: BorderRadius.circular(3))),
                            const SizedBox(width: 6),
                            Text(sortedCategories[i].key, style: const TextStyle(fontSize: 12)),
                          ]);
                        }),
                      ),
                    ]),
                  ),
                ],

                if (expenses.isEmpty)
                  Center(
                    child: Column(children: [
                      const SizedBox(height: 80),
                      Icon(Icons.bubble_chart_outlined,
                          size: 100, color: cs.primary.withValues(alpha: 0.1)),
                      const SizedBox(height: 24),
                      Text('Starting your journey?',
                          style: TextStyle(
                              color: cs.onSurface,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Log your first expense using the mic!',
                          style: TextStyle(color: cs.onSurfaceVariant)),
                    ]),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final double value;
  final String sym;
  final IconData icon;
  final Color iconColor;
  const _MiniStat({required this.label, required this.value, required this.sym, required this.icon, required this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: iconColor, size: 14),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ]),
      const SizedBox(height: 4),
      Text('$sym${value.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
    ]);
  }
}

class _SummaryActionCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final double value;
  final String sym;
  final VoidCallback onTap;
  final ColorScheme cs;

  const _SummaryActionCard({required this.label, required this.icon, required this.color, required this.value, required this.sym, required this.onTap, required this.cs});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text('$sym${value.toStringAsFixed(0)}',
              style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
        ]),
      ),
    );
  }
}

class _GoalMiniCard extends StatelessWidget {
  final GoalModel goal;
  final String sym;
  const _GoalMiniCard({required this.goal, required this.sym});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(goal.emoji, style: const TextStyle(fontSize: 20)),
          Text('${(goal.progress * 100).toInt()}%',
              style: TextStyle(
                  color: cs.primary, fontSize: 10, fontWeight: FontWeight.bold)),
        ]),
        const Spacer(),
        Text(goal.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: goal.progress,
            minHeight: 4,
            backgroundColor: cs.surfaceContainerHigh,
            valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
          ),
        ),
      ]),
    );
  }
}

class _DayData {
  final DateTime day;
  final double total;
  _DayData({required this.day, required this.total});
}
