import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/providers/settings_provider.dart';
import '../../../expenses/presentation/providers/expense_provider.dart';
import '../../../income/presentation/providers/income_provider.dart';
import '../../../budget/presentation/providers/budget_provider.dart';
import '../../../goals/presentation/providers/goal_provider.dart';
import '../../../ai/ai_service.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<String>? _aiInsights;
  bool _loadingInsights = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInsights() async {
    if (_loadingInsights) return;
    setState(() => _loadingInsights = true);
    try {
      final expenses = ref.read(expenseListProvider).asData?.value ?? [];
      final income = ref.read(incomeListProvider).asData?.value ?? [];
      final budgets = ref.read(budgetMapProvider).asData?.value ?? {};
      final goals = ref.read(goalListProvider).asData?.value ?? [];

      final budgetMap = <String, dynamic>{};
      budgets.forEach((k, v) => budgetMap[k] = v.monthlyLimit);
      final goalList = goals
          .map((g) =>
              {'title': g.title, 'progress': '${(g.progress * 100).toInt()}%'})
          .toList();

      final insights = await ref.read(aiServiceProvider).getInsights(
            expenses: expenses,
            income: income,
            budgets: budgetMap,
            goals: goalList,
          );
      if (mounted) setState(() => _aiInsights = insights);
    } catch (e) {
      if (mounted) {
        setState(() => _aiInsights = ['Error loading insights: $e']);
      }
    } finally {
      if (mounted) setState(() => _loadingInsights = false);
    }
  }

  void _copyReport() {
    final expenses = ref.read(expenseListProvider).asData?.value ?? [];
    final income = ref.read(incomeListProvider).asData?.value ?? [];
    final settings = ref.read(settingsProvider);
    final sym = settings.currencySymbol;
    final now = DateTime.now();

    final monthlyExp = expenses
        .where((e) => e.date.year == now.year && e.date.month == now.month);
    final totalSpent = monthlyExp.fold(0.0, (s, e) => s + e.amount);
    final totalIncome = income.fold(0.0, (s, i) => s + i.amount);

    final catTotals = <String, double>{};
    for (var e in monthlyExp) {
      catTotals[e.category] = (catTotals[e.category] ?? 0) + e.amount;
    }
    final sorted = catTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final buffer = StringBuffer();
    buffer.writeln('📊 Amar Wallet — ${DateFormat('MMMM yyyy').format(now)}');
    buffer.writeln('─────────────────────────');
    buffer.writeln('💰 Income: $sym${totalIncome.toStringAsFixed(0)}');
    buffer.writeln('💸 Expenses: $sym${totalSpent.toStringAsFixed(0)}');
    buffer.writeln(
        '📈 Balance: $sym${(totalIncome - totalSpent).toStringAsFixed(0)}');
    buffer.writeln('');
    buffer.writeln('Category Breakdown:');
    for (final entry in sorted) {
      final pct = (entry.value / totalSpent * 100).toInt();
      buffer.writeln('  ${entry.key}: $sym${entry.value.toStringAsFixed(0)} ($pct%)');
    }
    if (_aiInsights != null) {
      buffer.writeln('');
      buffer.writeln('AI Insights:');
      for (final insight in _aiInsights!) {
        buffer.writeln('  • $insight');
      }
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('📋 Report copied to clipboard!')),
    );
  }

  static const List<Color> _chartColors = [
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
    final cs = Theme.of(context).colorScheme;
    final expenseState = ref.watch(expenseListProvider);
    final incomeAsync = ref.watch(incomeListProvider);
    final settings = ref.watch(settingsProvider);
    final sym = settings.currencySymbol;

    return Scaffold(
      backgroundColor: cs.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: cs.surface,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
              title: Text('Analytics',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: cs.primary, fontWeight: FontWeight.bold)),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.copy_rounded, color: cs.primary),
                tooltip: 'Copy Report',
                onPressed: _copyReport,
              ),
              const SizedBox(width: 8),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TabBar(
                  controller: _tabController,
                  onTap: (_) => setState(() {}),
                  labelColor: cs.onSurface,
                  unselectedLabelColor: cs.onSurfaceVariant,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  dividerHeight: 0,
                  tabs: const [
                    Tab(text: 'Weekly'),
                    Tab(text: 'Monthly'),
                    Tab(text: 'Yearly'),
                  ],
                ),
              ),
            ),
          ),
          expenseState.when(
            loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator())),
            error: (e, _) =>
                SliverFillRemaining(child: Center(child: Text('Error: $e'))),
            data: (expenses) {
              final allIncome = incomeAsync.asData?.value ?? [];
              final now = DateTime.now();
              final totalIncome =
                  allIncome.fold(0.0, (s, i) => s + i.amount);
              final totalSpent =
                  expenses.fold(0.0, (s, e) => s + e.amount);

              // Per-tab data
              final tabIndex = _tabController.index;
              late List<_ChartPoint> trendData;
              late Map<String, double> catTotals;
              late double periodSpent;
              late double prevPeriodSpent;
              late String periodLabel;

              if (tabIndex == 0) {
                // Weekly
                periodLabel = 'This Week';
                final weekStart =
                    now.subtract(Duration(days: now.weekday - 1));
                final lastWeekStart =
                    weekStart.subtract(const Duration(days: 7));
                trendData = List.generate(7, (i) {
                  final day = weekStart.add(Duration(days: i));
                  final total = expenses
                      .where((e) =>
                          e.date.year == day.year &&
                          e.date.month == day.month &&
                          e.date.day == day.day)
                      .fold(0.0, (s, e) => s + e.amount);
                  return _ChartPoint(
                      label: DateFormat('E').format(day), value: total);
                });
                catTotals = {};
                final weekExpenses =
                    expenses.where((e) => e.date.isAfter(weekStart));
                periodSpent =
                    weekExpenses.fold(0.0, (s, e) => s + e.amount);
                for (var e in weekExpenses) {
                  catTotals[e.category] =
                      (catTotals[e.category] ?? 0) + e.amount;
                }
                prevPeriodSpent = expenses
                    .where((e) =>
                        e.date.isAfter(lastWeekStart) &&
                        e.date.isBefore(weekStart))
                    .fold(0.0, (s, e) => s + e.amount);
              } else if (tabIndex == 1) {
                // Monthly
                periodLabel = DateFormat('MMMM').format(now);
                trendData = List.generate(
                    DateTime(now.year, now.month + 1, 0).day, (i) {
                  final day =
                      DateTime(now.year, now.month, i + 1);
                  final total = expenses
                      .where((e) =>
                          e.date.year == day.year &&
                          e.date.month == day.month &&
                          e.date.day == day.day)
                      .fold(0.0, (s, e) => s + e.amount);
                  return _ChartPoint(label: '${i + 1}', value: total);
                });
                catTotals = {};
                final monthExp = expenses.where((e) =>
                    e.date.year == now.year &&
                    e.date.month == now.month);
                periodSpent =
                    monthExp.fold(0.0, (s, e) => s + e.amount);
                for (var e in monthExp) {
                  catTotals[e.category] =
                      (catTotals[e.category] ?? 0) + e.amount;
                }
                final prevMonth = DateTime(now.year, now.month - 1);
                prevPeriodSpent = expenses
                    .where((e) =>
                        e.date.year == prevMonth.year &&
                        e.date.month == prevMonth.month)
                    .fold(0.0, (s, e) => s + e.amount);
              } else {
                // Yearly
                periodLabel = '${now.year}';
                trendData = List.generate(12, (i) {
                  final total = expenses
                      .where((e) =>
                          e.date.year == now.year &&
                          e.date.month == i + 1)
                      .fold(0.0, (s, e) => s + e.amount);
                  return _ChartPoint(
                      label: DateFormat('MMM')
                          .format(DateTime(now.year, i + 1)),
                      value: total);
                });
                catTotals = {};
                final yearExp = expenses
                    .where((e) => e.date.year == now.year);
                periodSpent =
                    yearExp.fold(0.0, (s, e) => s + e.amount);
                for (var e in yearExp) {
                  catTotals[e.category] =
                      (catTotals[e.category] ?? 0) + e.amount;
                }
                prevPeriodSpent = expenses
                    .where((e) => e.date.year == now.year - 1)
                    .fold(0.0, (s, e) => s + e.amount);
              }

              final sortedCats = catTotals.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));
              final changePercent = prevPeriodSpent > 0
                  ? ((periodSpent - prevPeriodSpent) / prevPeriodSpent * 100)
                  : 0.0;

              // Stats
              final avgDaily = tabIndex == 0
                  ? periodSpent / 7
                  : tabIndex == 1
                      ? periodSpent /
                          DateTime(now.year, now.month + 1, 0).day
                      : periodSpent / 365;
              final savingsRate = totalIncome > 0
                  ? ((totalIncome - totalSpent) / totalIncome * 100)
                  : 0.0;
              final topCategory =
                  sortedCats.isNotEmpty ? sortedCats.first.key : 'N/A';

              return SliverPadding(
                padding:
                    const EdgeInsets.only(left: 24, right: 24, bottom: 140, top: 16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ── Summary Cards ────────────────────────────
                    Row(children: [
                      Expanded(
                          child: _StatMini(
                              label: periodLabel,
                              value: '$sym${periodSpent.toStringAsFixed(0)}',
                              icon: Icons.trending_up_rounded,
                              color: cs.primary,
                              cs: cs)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _StatMini(
                              label: 'vs Previous',
                              value:
                                  '${changePercent >= 0 ? '+' : ''}${changePercent.toStringAsFixed(0)}%',
                              icon: changePercent >= 0
                                  ? Icons.arrow_upward_rounded
                                  : Icons.arrow_downward_rounded,
                              color: changePercent >= 0
                                  ? cs.error
                                  : Colors.green,
                              cs: cs)),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                          child: _StatMini(
                              label: 'Avg Daily',
                              value: '$sym${avgDaily.toStringAsFixed(0)}',
                              icon: Icons.calendar_today_rounded,
                              color: cs.tertiary,
                              cs: cs)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _StatMini(
                              label: 'Savings Rate',
                              value: '${savingsRate.toStringAsFixed(0)}%',
                              icon: Icons.savings_rounded,
                              color: Colors.green,
                              cs: cs)),
                    ]),
                    const SizedBox(height: 24),

                    // ── Spending Trend ─────────────────────────────
                    Text('Spending Trend',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: cs.primary)),
                    const SizedBox(height: 16),
                    Container(
                      height: 200,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: trendData.every((d) => d.value == 0)
                          ? Center(
                              child: Text('No data for this period',
                                  style: TextStyle(
                                      color: cs.onSurfaceVariant)))
                          : LineChart(LineChartData(
                              gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  horizontalInterval:
                                      (trendData.map((d) => d.value).reduce(
                                                      (a, b) =>
                                                          a > b ? a : b) /
                                                  3)
                                              .clamp(1, 1000000) +
                                          0.0),
                              titlesData: FlTitlesData(
                                show: true,
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 22,
                                    interval: tabIndex == 1
                                        ? 5
                                        : 1,
                                    getTitlesWidget: (v, _) {
                                      final i = v.toInt();
                                      if (i < 0 ||
                                          i >= trendData.length) {
                                        return const SizedBox();
                                      }
                                      return Text(
                                          trendData[i].label,
                                          style: TextStyle(
                                              fontSize: 9,
                                              color:
                                                  cs.onSurfaceVariant));
                                    },
                                  ),
                                ),
                                leftTitles: const AxisTitles(
                                    sideTitles: SideTitles(
                                        showTitles: false)),
                                topTitles: const AxisTitles(
                                    sideTitles: SideTitles(
                                        showTitles: false)),
                                rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(
                                        showTitles: false)),
                              ),
                              borderData: FlBorderData(show: false),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: List.generate(
                                      trendData.length,
                                      (i) => FlSpot(i.toDouble(),
                                          trendData[i].value)),
                                  isCurved: true,
                                  color: cs.primary,
                                  barWidth: 3,
                                  isStrokeCapRound: true,
                                  dotData:
                                      const FlDotData(show: false),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: cs.primary
                                        .withValues(alpha: 0.08),
                                  ),
                                ),
                              ],
                            )),
                    ),
                    const SizedBox(height: 24),

                    // ── Category Breakdown ───────────────────────
                    if (sortedCats.isNotEmpty) ...[
                      Text('Category Breakdown',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: cs.primary)),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          children: sortedCats
                              .asMap()
                              .entries
                              .map((entry) {
                            final i = entry.key;
                            final cat = entry.value;
                            final pct = periodSpent > 0
                                ? cat.value / periodSpent
                                : 0.0;
                            return Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 14),
                              child: Row(children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: _chartColors[
                                        i % _chartColors.length],
                                    borderRadius:
                                        BorderRadius.circular(3),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment
                                                .spaceBetween,
                                        children: [
                                          Text(cat.key,
                                              style: const TextStyle(
                                                  fontWeight:
                                                      FontWeight
                                                          .w600,
                                                  fontSize: 13)),
                                          Text(
                                              '$sym${cat.value.toStringAsFixed(0)} (${(pct * 100).toInt()}%)',
                                              style: TextStyle(
                                                  color: cs
                                                      .onSurfaceVariant,
                                                  fontSize: 12)),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(4),
                                        child:
                                            LinearProgressIndicator(
                                          value: pct,
                                          minHeight: 6,
                                          backgroundColor: cs
                                              .surfaceContainerHigh,
                                          valueColor:
                                              AlwaysStoppedAnimation(
                                                  _chartColors[i %
                                                      _chartColors
                                                          .length]),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ]),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // ── Top Insights ──────────────────────────────
                    Text('Top Category',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: cs.primary)),
                    const SizedBox(height: 12),
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
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.emoji_events_rounded,
                              color: Colors.amber, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(topCategory,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                              Text(
                                sortedCats.isNotEmpty
                                    ? '$sym${sortedCats.first.value.toStringAsFixed(0)} spent'
                                    : 'No data',
                                style: TextStyle(
                                    color: Colors.white
                                        .withValues(alpha: 0.7)),
                              ),
                            ],
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 24),

                    // ── AI Insights ──────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('AI Insights',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: cs.primary)),
                        if (_aiInsights == null)
                          TextButton.icon(
                            onPressed:
                                _loadingInsights ? null : _loadInsights,
                            icon: _loadingInsights
                                ? SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: cs.primary))
                                : Icon(Icons.auto_awesome,
                                    color: cs.primary, size: 18),
                            label: Text(_loadingInsights
                                ? 'Loading...'
                                : 'Generate'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_aiInsights != null)
                      ...(_aiInsights!.asMap().entries.map((entry) {
                        final icons = [
                          Icons.insights_rounded,
                          Icons.trending_up_rounded,
                          Icons.lightbulb_outline_rounded,
                          Icons.savings_rounded,
                          Icons.emoji_events_rounded,
                        ];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: cs.outlineVariant
                                    .withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Icon(
                                  icons[entry.key % icons.length],
                                  color: cs.primary,
                                  size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(entry.value,
                                    style: TextStyle(
                                        color: cs.onSurface,
                                        fontSize: 13,
                                        height: 1.4)),
                              ),
                            ],
                          ),
                        );
                      }))
                    else
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            'Tap "Generate" to get AI-powered financial insights',
                            style: TextStyle(
                                color: cs.onSurfaceVariant, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ]),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatMini extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final ColorScheme cs;
  const _StatMini(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color,
      required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration:
                BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 16),
          ),
          const Spacer(),
        ]),
        const SizedBox(height: 10),
        Text(value,
            style: TextStyle(
                color: cs.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        Text(label,
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11)),
      ]),
    );
  }
}

class _ChartPoint {
  final String label;
  final double value;
  _ChartPoint({required this.label, required this.value});
}
