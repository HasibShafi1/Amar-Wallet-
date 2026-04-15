import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/theme.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../core/utils/voice_command_parser.dart';
import '../../../voice/voice_service.dart';
import '../../../voice/presentation/widgets/voice_pulse_button.dart';
import '../../../ai/ai_service.dart';
import '../../../expenses/presentation/widgets/confirmation_dialog.dart';
import '../../../expenses/presentation/providers/expense_provider.dart';
import '../../../income/presentation/providers/income_provider.dart';
import '../../../ledger/presentation/providers/ledger_provider.dart';
import 'dashboard_screen.dart';
import '../../../analytics/presentation/screens/analytics_screen.dart';
import '../../../expenses/presentation/screens/expense_history_screen.dart';
import '../../../profile/presentation/screens/settings_screen.dart';

class MainLayout extends ConsumerStatefulWidget {
  const MainLayout({super.key});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  int _currentIndex = 0;
  bool _isProcessingAI = false;
  String? _lastProcessedText;

  final List<Widget> _screens = const [
    DashboardScreen(),
    ExpenseHistoryScreen(),
    AnalyticsScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Init category engine
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupListeners();
    });
  }

  void _setupListeners() {
    ref.listenManual(voiceServiceProvider, (previous, next) {
      if (!mounted) return;

      final text = next.currentText;
      final wasListening = previous?.isListening ?? false;
      final stoppedListening = wasListening && !next.isListening;

      // Process when STT stops with captured text (avoid double-processing)
      if (stoppedListening && text.isNotEmpty && text != _lastProcessedText) {
        _lastProcessedText = text;

        // 1. Check for local voice commands first (no AI needed)
        final command = VoiceCommandParser.parse(text);
        if (command.isCommand) {
          _handleVoiceCommand(command, next.isContinuousMode);
          return;
        }

        // 2. Process as financial input
        _processVoiceInput(text, continuousMode: next.isContinuousMode);
        return;
      }

      // 3. If stopped but not processed (e.g. duplicate or empty), clear UI
      if (stoppedListening && !next.isListening) {
        ref.read(voiceServiceProvider.notifier).clearText();
      }

      // Show voice errors
      if (next.hasError &&
          next.errorMessage.isNotEmpty &&
          (previous == null || previous.errorMessage != next.errorMessage)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(children: [
                  const Icon(Icons.mic_off, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Expanded(child: Text(next.errorMessage)),
                ]),
                backgroundColor: AmarTheme.error,
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'Retry',
                  textColor: Colors.white70,
                  onPressed: () =>
                      ref.read(voiceServiceProvider.notifier).startListening(),
                ),
              ),
            );
          }
        });
      }
    });
  }

  void _handleVoiceCommand(VoiceCommand command, bool wasInContinuous) {
    switch (command.type) {
      case VoiceCommandType.undo:
        // Delete the last added expense
        final expenses = ref.read(expenseListProvider).asData?.value ?? [];
        if (expenses.isNotEmpty) {
          ref.read(expenseListProvider.notifier).deleteExpense(expenses.first.id);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('↩️ Last expense undone'), duration: Duration(seconds: 2)),
          );
        }
        // Resume continuous if needed
        if (wasInContinuous) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              final locale = ref.read(settingsProvider).voiceLanguage;
              ref.read(voiceServiceProvider.notifier).startListening(continuous: true, localeId: locale);
            }
          });
        }
      case VoiceCommandType.stopContinuous:
        ref.read(voiceServiceProvider.notifier).stopListening();
      case VoiceCommandType.none:
        break;
    }
  }

  void _handleVoiceToggle() {
    final voiceState = ref.read(voiceServiceProvider);
    final notifier = ref.read(voiceServiceProvider.notifier);
    if (voiceState.isListening) {
      notifier.stopListening();
    } else {
      final locale = ref.read(settingsProvider).voiceLanguage;
      notifier.startListening(continuous: false, localeId: locale);
    }
  }

  void _handleVoiceLongPress() {
    final voiceState = ref.read(voiceServiceProvider);
    final notifier = ref.read(voiceServiceProvider.notifier);
    if (voiceState.isListening) {
      notifier.stopListening();
    } else {
      final locale = ref.read(settingsProvider).voiceLanguage;
      notifier.startListening(continuous: true, localeId: locale);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔴 Continuous mode — say expenses one by one. Long-press to stop.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _processVoiceInput(String text, {bool continuousMode = false}) async {
    if (text.isEmpty || !mounted) return;
    ref.read(voiceServiceProvider.notifier).clearText();
    setState(() => _isProcessingAI = true);

    try {
      final aiService = ref.read(aiServiceProvider);
      final actions = await aiService.parseVoiceInput(text);

      if (!mounted) return;

      for (final action in actions) {
        await _handleAction(action);
      }

      // In continuous mode, auto-restart listening after processing
      if (continuousMode && mounted) {
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) {
          final locale = ref.read(settingsProvider).voiceLanguage;
          ref.read(voiceServiceProvider.notifier).startListening(continuous: true, localeId: locale);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessingAI = false);
    }
  }

  Future<void> _handleAction(VoiceAction action) async {
    if (!mounted) return;

    switch (action) {
      case ExpenseAction(:final expenses):
        if (expenses.isEmpty) return;
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => ConfirmationDialog(
            parsedExpenses: expenses,
            onConfirm: (confirmed) {
              ref.read(expenseListProvider.notifier).addMultiple(confirmed);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✅ ${confirmed.length} expense(s) saved!'),
                  backgroundColor: Colors.green.shade700,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        );

      case IncomeAction(:final income):
        await ref.read(incomeListProvider.notifier).add(income);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('💰 Income ৳${income.amount.toStringAsFixed(0)} (${income.source}) saved!'),
              backgroundColor: Colors.green.shade700,
              duration: const Duration(seconds: 2),
            ),
          );
        }

      case LedgerAction(:final entry):
        await ref.read(ledgerListProvider.notifier).add(entry);
        if (mounted) {
          final label = entry.type == 'lent' ? '⬆️ Lent' : '⬇️ Borrowed';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$label ৳${entry.amount.toStringAsFixed(0)} ${entry.type == "lent" ? "to" : "from"} ${entry.person}'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final voiceState = ref.watch(voiceServiceProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      extendBody: true,
      backgroundColor: cs.surface,
      body: Stack(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: KeyedSubtree(
              key: ValueKey(_currentIndex),
              child: _screens[_currentIndex],
            ),
          ),

          // AI processing overlay
          if (_isProcessingAI)
            Positioned.fill(
              child: Container(
                color: Colors.black12,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20)],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 24, height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                        ),
                        SizedBox(width: 16),
                        Text('Analyzing...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Continuous mode banner
          if (voiceState.isContinuousMode)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.red.shade700,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.red.withValues(alpha: 0.3), blurRadius: 12)],
                ),
                child: Row(children: [
                  const Icon(Icons.fiber_manual_record, color: Colors.white, size: 14),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Continuous logging — say expenses one by one',
                        style: TextStyle(color: Colors.white, fontSize: 13)),
                  ),
                  GestureDetector(
                    onTap: () => ref.read(voiceServiceProvider.notifier).stopListening(),
                    child: const Icon(Icons.stop_circle_outlined, color: Colors.white),
                  ),
                ]),
              ),
            ),

          // Live transcription bubble
          if (voiceState.currentText.isNotEmpty && voiceState.isListening)
            Positioned(
              bottom: 130,
              left: 24,
              right: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 20, offset: const Offset(0, 10))],
                  border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
                ),
                child: Row(children: [
                  Icon(Icons.mic_rounded, color: cs.primary, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '"${voiceState.currentText}"',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic, color: cs.onSurface,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ]),
              ),
            ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(top: 30.0),
        child: GestureDetector(
          onLongPress: _handleVoiceLongPress,
          child: VoicePulseButton(
            isListening: voiceState.isListening,
            isContinuous: voiceState.isContinuousMode,
            onTap: _handleVoiceToggle,
          ),
        ),
      ),
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: BottomAppBar(
            color: cs.surfaceContainerLowest.withValues(alpha: 0.85),
            elevation: 0,
            notchMargin: 12,
            shape: const CircularNotchedRectangle(),
            child: SizedBox(
              height: 70,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(icon: Icons.home_rounded, label: 'Home', index: 0, current: _currentIndex, onTap: () => setState(() => _currentIndex = 0)),
                  _NavItem(icon: Icons.receipt_long_rounded, label: 'History', index: 1, current: _currentIndex, onTap: () => setState(() => _currentIndex = 1)),
                  const SizedBox(width: 56),
                  _NavItem(icon: Icons.analytics_rounded, label: 'Analytics', index: 2, current: _currentIndex, onTap: () => setState(() => _currentIndex = 2)),
                  _NavItem(icon: Icons.tune_rounded, label: 'Settings', index: 3, current: _currentIndex, onTap: () => setState(() => _currentIndex = 3)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int current;
  final VoidCallback onTap;

  const _NavItem({required this.icon, required this.label, required this.index, required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final selected = index == current;
    final color = selected ? cs.primary : cs.onSurfaceVariant.withValues(alpha: 0.5);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 3),
            Text(
              label.toUpperCase(),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: color,
                fontSize: 9,
                fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
