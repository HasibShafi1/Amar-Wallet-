import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../ai/ai_service.dart';
import '../../../expenses/presentation/providers/expense_provider.dart';
import '../../../income/presentation/providers/income_provider.dart';
import '../../../goals/presentation/providers/goal_provider.dart';
import '../../../budget/presentation/providers/budget_provider.dart';

class AIInsightsScreen extends ConsumerStatefulWidget {
  const AIInsightsScreen({super.key});

  @override
  ConsumerState<AIInsightsScreen> createState() => _AIInsightsScreenState();
}

class _AIInsightsScreenState extends ConsumerState<AIInsightsScreen> {
  bool _isLoading = false;
  List<String> _insights = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInsights();
    });
  }

  Future<void> _loadInsights() async {
    final expenses = ref.read(expenseListProvider).value ?? [];
    final income = ref.read(incomeListProvider).value ?? [];
    final budgets = ref.read(budgetMapProvider).value ?? {};
    final goals = ref.read(goalListProvider).value ?? [];

    if (expenses.isEmpty && income.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final aiService = ref.read(aiServiceProvider);
      // Map budgets and goals to simple types for AI prompt
      final budgetMap = budgets.map((k, v) => MapEntry(k, v.monthlyLimit));
      final goalsList = goals.map((g) => {'title': g.title, 'progress': g.progress}).toList();

      final insights = await aiService.getInsights(
        expenses: expenses,
        income: income,
        budgets: budgetMap,
        goals: goalsList,
      );
      if (mounted) setState(() => _insights = insights);
    } catch (e) {
      if (mounted) {
        setState(() => _insights = ["Welcome! Please add your Gemini API Key in Settings to receive deep personalized insights."]);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: cs.surface,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [cs.primary, cs.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 40),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Financial Intelligence',
                        style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              title: const Text('AI Insights'),
              centerTitle: true,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isLoading)
                    Center(
                      child: Column(
                        children: [
                          const SizedBox(height: 60),
                          const CircularProgressIndicator(),
                          const SizedBox(height: 24),
                          Text('Analyzing your financial logic...', 
                               style: TextStyle(color: cs.onSurfaceVariant)),
                        ],
                      ),
                    )
                  else if (_insights.isEmpty)
                    Center(
                      child: Column(
                        children: [
                          const SizedBox(height: 40),
                          Icon(Icons.psychology_outlined, size: 80, color: cs.primary.withValues(alpha: 0.2)),
                          const SizedBox(height: 16),
                          const Text('No insights yet. Try logging some expenses!'),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _loadInsights,
                            child: const Text('Generate Insights'),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._insights.asMap().entries.map((entry) {
                      final i = entry.key;
                      final text = entry.value;
                      return _InsightCard(index: i, text: text, cs: cs);
                    }),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loadInsights,
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('Refresh'),
        backgroundColor: cs.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final int index;
  final String text;
  final ColorScheme cs;

  const _InsightCard({required this.index, required this.text, required this.cs});

  @override
  Widget build(BuildContext context) {
    // Determine icon based on text keywords
    IconData icon = Icons.lightbulb_outline_rounded;
    Color color = cs.primary;
    
    if (text.toLowerCase().contains('budget') || text.toLowerCase().contains('%')) {
      icon = Icons.pie_chart_rounded;
      color = Colors.orange;
    } else if (text.toLowerCase().contains('save') || text.toLowerCase().contains('goal')) {
      icon = Icons.savings_rounded;
      color = Colors.green;
    } else if (text.toLowerCase().contains('warning') || text.toLowerCase().contains('high')) {
      icon = Icons.warning_amber_rounded;
      color = cs.error;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
