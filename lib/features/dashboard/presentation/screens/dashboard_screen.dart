import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/theme.dart';
import '../../../expenses/presentation/providers/expense_provider.dart';
import '../../../voice/voice_service.dart';
import '../../../voice/presentation/widgets/voice_pulse_button.dart';
import '../../../ai/ai_service.dart';
import '../../../expenses/presentation/widgets/confirmation_dialog.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _isProcessingAI = false;

  void _handleVoiceToggle() async {
    final voiceState = ref.read(voiceServiceProvider);
    final voiceNotifier = ref.read(voiceServiceProvider.notifier);

    if (voiceState.isListening) {
      await voiceNotifier.stopListening();
      _processVoiceInput(voiceState.currentText);
    } else {
      await voiceNotifier.startListening();
    }
  }

  Future<void> _processVoiceInput(String text) async {
    if (text.isEmpty) return;
    
    setState(() => _isProcessingAI = true);
    
    try {
      final aiService = ref.read(aiServiceProvider);
      final expenses = await aiService.parseExpenses(text);
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => ConfirmationDialog(
            parsedExpenses: expenses,
            onConfirm: (confirmed) {
              ref.read(expenseListProvider.notifier).addMultiple(confirmed);
            },
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        if (e.toString().contains('API Key is missing')) {
          _showApiKeyDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error parsing: $e')),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isProcessingAI = false);
    }
  }

  void _showApiKeyDialog() {
    final aiService = ref.read(aiServiceProvider);
    String inputKey = '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Gemini API Key'),
        content: TextField(
          onChanged: (v) => inputKey = v,
          decoration: const InputDecoration(hintText: 'AI API Key'),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await aiService.saveApiKey(inputKey);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          )
        ],
      ),
    );
  }

  void _showInsights() async {
    final expensesState = ref.read(expenseListProvider);
    final expenses = expensesState.value ?? [];
    
    setState(() => _isProcessingAI = true);
    
    try {
      final aiService = ref.read(aiServiceProvider);
      final insights = await aiService.getInsights(expenses);
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => Dialog(
            backgroundColor: AmarTheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AI Insights', style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: AmarTheme.tertiary)),
                  const SizedBox(height: 16),
                  ...insights.map((i) => Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.flare, color: AmarTheme.tertiary, size: 20),
                        const SizedBox(width: 8),
                        Expanded(child: Text(i, style: Theme.of(context).textTheme.bodyLarge)),
                      ],
                    ),
                  )),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  )
                ],
              ),
            ),
          )
        );
      }
    } catch (e) {
      if (mounted && e.toString().contains('API Key is missing')) {
        _showApiKeyDialog();
      }
    } finally {
      if (mounted) setState(() => _isProcessingAI = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final voiceState = ref.watch(voiceServiceProvider);
    final expenseState = ref.watch(expenseListProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('AmarWallet', style: Theme.of(context).textTheme.displayMedium),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.settings),
                        onPressed: _showApiKeyDialog,
                      ),
                      IconButton(
                        icon: const Icon(Icons.auto_awesome),
                        color: AmarTheme.tertiary,
                        onPressed: _showInsights,
                      ),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 40),
              
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AmarTheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Expenses', style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 8),
                    expenseState.when(
                      data: (expenses) {
                        final total = expenses.fold(0.0, (sum, e) => sum + e.amount);
                        return Text(
                          NumberFormat.currency(symbol: '\$').format(total),
                          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            color: AmarTheme.primary,
                          ),
                        );
                      },
                      loading: () => const CircularProgressIndicator(),
                      error: (err, st) => Text('Error: $err'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              
              Text('Recent Transactions', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              
              Expanded(
                child: expenseState.when(
                  data: (expenses) {
                    if (expenses.isEmpty) {
                      return Center(
                        child: Text(
                          'No expenses yet. Tap the mic to start.',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.only(bottom: 180), // clear space for FAB
                      itemCount: expenses.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 24),
                      itemBuilder: (context, index) {
                        final exp = expenses[index];
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AmarTheme.surfaceContainerLow,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(Icons.receipt_long, color: AmarTheme.primary),
                                ),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(exp.description, style: Theme.of(context).textTheme.titleMedium),
                                    Text(exp.category, style: Theme.of(context).textTheme.labelMedium),
                                  ],
                                ),
                              ],
                            ),
                            Text(
                              NumberFormat.currency(symbol: '\$').format(exp.amount),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ],
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, st) => Center(child: Text('Error: $err')),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (voiceState.currentText.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 16, left: 32, right: 32),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AmarTheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: Text(
                'Listening: "${voiceState.currentText}"',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
          if (_isProcessingAI)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AmarTheme.primaryContainer,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                  SizedBox(width: 8),
                  Text('Parsing...', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          VoicePulseButton(
            isListening: voiceState.isListening,
            onTap: _handleVoiceToggle,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
