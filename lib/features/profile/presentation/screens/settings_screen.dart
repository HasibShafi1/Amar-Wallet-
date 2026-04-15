import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../ai/ai_service.dart';
import '../../../budget/data/models/budget_model.dart';
import '../../../budget/presentation/providers/budget_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _keyController = TextEditingController();
  bool _isTestingKey = false;
  bool _keyVisible = false;
  String? _keyStatus; // null = not tested, 'ok', 'fail'

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _saveKey() async {
    final key = _keyController.text.trim();
    if (key.isEmpty) return;
    await ref.read(aiServiceProvider).saveApiKey(key);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ API Key saved securely')),
      );
      _keyController.clear();
      FocusScope.of(context).unfocus();
      setState(() => _keyStatus = null);
    }
  }

  Future<void> _testKey() async {
    final key = _keyController.text.trim();
    if (key.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a key first to test')),
      );
      return;
    }
    setState(() { _isTestingKey = true; _keyStatus = null; });
    try {
      // Save the key temporarily and test parsing a dummy string
      await ref.read(aiServiceProvider).saveApiKey(key);
      final result = await ref.read(aiServiceProvider).parseExpenses('Spent 10 on coffee');
      setState(() => _keyStatus = result.isNotEmpty ? 'ok' : 'fail');
    } catch (_) {
      setState(() => _keyStatus = 'fail');
    } finally {
      if (mounted) setState(() => _isTestingKey = false);
    }
  }

  Future<void> _showCurrencyPicker() async {
    final selected = await showModalBottomSheet<Map<String, String>>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CurrencyPickerSheet(),
    );
    if (selected != null) {
      ref.read(settingsProvider.notifier).setCurrency(selected['code']!, selected['symbol']!);
    }
  }

  Future<void> _showBudgetDialog(BuildContext context, WidgetRef ref, BudgetModel? budget) async {
    final catCtrl = TextEditingController(text: budget?.category ?? '');
    final limitCtrl = TextEditingController(text: budget?.monthlyLimit.toStringAsFixed(0) ?? '');
    final isEdit = budget != null;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Edit Budget' : 'Add Budget'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: catCtrl,
              decoration: const InputDecoration(labelText: 'Category', hintText: 'e.g. Food'),
              enabled: !isEdit,
              autofocus: !isEdit,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: limitCtrl,
              decoration: const InputDecoration(labelText: 'Monthly Limit'),
              keyboardType: TextInputType.number,
              autofocus: isEdit,
            ),
          ],
        ),
        actions: [
          if (isEdit)
            TextButton(
              onPressed: () {
                ref.read(budgetListProvider.notifier).deleteBudget(budget.category);
                Navigator.pop(ctx, true);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final limit = double.tryParse(limitCtrl.text) ?? 0;
              if (catCtrl.text.isNotEmpty && limit > 0) {
                ref.read(budgetListProvider.notifier).upsertBudget(catCtrl.text, limit);
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true) {
      // Refresh handled by provider
    }
  }

  void _showAvatarPicker(BuildContext context) {
    const avatars = ['👤', '😎', '🧑‍💼', '👩‍💻', '🧕', '🦸', '🐼', '🦊', '🐯', '🦁', '🦉', '🐸'];
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Choose Avatar',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: avatars.map((e) => GestureDetector(
                onTap: () {
                  ref.read(settingsProvider.notifier).setUserAvatar(e);
                  Navigator.pop(ctx);
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cs.outlineVariant),
                  ),
                  child: Text(e, style: const TextStyle(fontSize: 28)),
                ),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _editProfileField(String label, String current, void Function(String) onSave) {
    final ctrl = TextEditingController(text: current);
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cs.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Edit $label'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: TextStyle(color: cs.onSurface),
          decoration: InputDecoration(
            labelText: label,
            filled: true,
            fillColor: cs.surfaceContainerLowest,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              onSave(ctrl.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final cs = Theme.of(context).colorScheme;

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
              title: Text(
                'Settings',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: cs.primary, fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.only(left: 24, right: 24, bottom: 140, top: 8),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // ── Profile Card ──────────────────────────────────────────
                _SectionHeader(title: 'Profile'),
                const SizedBox(height: 12),
                _SettingsCard(children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(children: [
                      GestureDetector(
                        onTap: () => _showAvatarPicker(context),
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: cs.primaryContainer,
                          child: Text(settings.userAvatar,
                              style: const TextStyle(fontSize: 28)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () => _editProfileField(
                                  'Name', settings.userName,
                                  (v) => ref.read(settingsProvider.notifier).setUserName(v)),
                              child: Text(
                                settings.userName.isEmpty ? 'Tap to set name' : settings.userName,
                                style: TextStyle(
                                  color: settings.userName.isEmpty ? cs.onSurfaceVariant : cs.onSurface,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            GestureDetector(
                              onTap: () => _editProfileField(
                                  'Email', settings.userEmail,
                                  (v) => ref.read(settingsProvider.notifier).setUserEmail(v)),
                              child: Text(
                                settings.userEmail.isEmpty ? 'Tap to set email' : settings.userEmail,
                                style: TextStyle(
                                  color: cs.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.edit_outlined, color: cs.onSurfaceVariant, size: 18),
                    ]),
                  ),
                ]),
                const SizedBox(height: 24),

                // ── AI / Intelligence ─────────────────────────────────────
                _SectionHeader(title: 'AI Intelligence'),
                const SizedBox(height: 12),
                _SettingsCard(children: [
                  // AI Enabled toggle
                  _ToggleTile(
                    icon: Icons.psychology_rounded,
                    iconColor: cs.tertiary,
                    title: 'Enable AI Features',
                    subtitle: 'Voice parsing & insights',
                    value: settings.aiEnabled,
                    onChanged: (v) => ref.read(settingsProvider.notifier).setAiEnabled(v),
                  ),
                  _Divider(),
                  // AI Provider selection
                  _TapTile(
                    icon: Icons.smart_toy_rounded,
                    iconColor: cs.primary,
                    title: 'AI Provider',
                    trailing: settings.aiProvider,
                    onTap: () async {
                      final providers = ['Gemini'];
                      final chosen = await showDialog<String>(
                        context: context,
                        builder: (ctx) => SimpleDialog(
                          title: const Text('Select AI Provider'),
                          children: providers.map((p) => SimpleDialogOption(
                            onPressed: () => Navigator.pop(ctx, p),
                            child: Text(p),
                          )).toList(),
                        ),
                      );
                      if (chosen != null) ref.read(settingsProvider.notifier).setAiProvider(chosen);
                    },
                  ),
                ]),
                const SizedBox(height: 24),

                // ── Voice Language ─────────────────────────────────────────
                _SectionHeader(title: 'Voice Language'),
                const SizedBox(height: 12),
                _SettingsCard(children: [
                  _TapTile(
                    icon: Icons.language_rounded,
                    iconColor: cs.tertiary,
                    title: 'Speech Language',
                    trailing: settings.voiceLanguage == 'bn_BD' ? 'বাংলা' : 'English',
                    onTap: () async {
                      final langs = [
                        {'id': 'en_US', 'name': 'English'},
                        {'id': 'bn_BD', 'name': 'বাংলা'},
                      ];
                      final chosen = await showDialog<String>(
                        context: context,
                        builder: (ctx) => SimpleDialog(
                          title: const Text('Voice Language'),
                          children: langs.map((l) => SimpleDialogOption(
                            onPressed: () => Navigator.pop(ctx, l['id']),
                            child: Row(children: [
                              if (l['id'] == settings.voiceLanguage)
                                Icon(Icons.check, color: cs.primary, size: 18)
                              else
                                const SizedBox(width: 18),
                              const SizedBox(width: 12),
                              Text(l['name']!),
                            ]),
                          )).toList(),
                        ),
                      );
                      if (chosen != null) {
                        ref.read(settingsProvider.notifier).setVoiceLanguage(chosen);
                      }
                    },
                  ),
                ]),
                const SizedBox(height: 24),

                // ── Notifications ──────────────────────────────────────────
                _SectionHeader(title: 'Notifications'),
                const SizedBox(height: 12),
                _SettingsCard(children: [
                  _ToggleTile(
                    icon: Icons.summarize_rounded,
                    iconColor: Colors.blue,
                    title: 'Daily Spending Summary',
                    subtitle: 'Get notified at ${settings.dailySummaryHour > 12 ? settings.dailySummaryHour - 12 : settings.dailySummaryHour}${settings.dailySummaryHour >= 12 ? 'PM' : 'AM'}',
                    value: settings.notifyDailySummary,
                    onChanged: (v) => ref.read(settingsProvider.notifier).setNotifyDailySummary(v),
                  ),
                  _Divider(),
                  _ToggleTile(
                    icon: Icons.warning_rounded,
                    iconColor: Colors.orange,
                    title: 'Budget Alerts',
                    subtitle: 'Alert when budget exceeds 80%',
                    value: settings.notifyBudgetAlerts,
                    onChanged: (v) => ref.read(settingsProvider.notifier).setNotifyBudgetAlerts(v),
                  ),
                  _Divider(),
                  _ToggleTile(
                    icon: Icons.flag_rounded,
                    iconColor: Colors.green,
                    title: 'Goal Reminders',
                    subtitle: 'Weekly encouragement for goals',
                    value: settings.notifyGoalReminders,
                    onChanged: (v) => ref.read(settingsProvider.notifier).setNotifyGoalReminders(v),
                  ),
                  _Divider(),
                  _ToggleTile(
                    icon: Icons.autorenew_rounded,
                    iconColor: Colors.purple,
                    title: 'Subscription Alerts',
                    subtitle: 'Remind before subscription due dates',
                    value: settings.notifySubscriptionDue,
                    onChanged: (v) => ref.read(settingsProvider.notifier).setNotifySubscriptionDue(v),
                  ),
                ]),
                const SizedBox(height: 24),

                // ── Monthly Budgets ───────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _SectionHeader(title: 'Monthly Budgets'),
                    IconButton(
                      icon: Icon(Icons.add_circle_outline_rounded, color: cs.primary, size: 20),
                      onPressed: () => _showBudgetDialog(context, ref, null),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ref.watch(budgetListProvider).when(
                  data: (budgets) => _SettingsCard(children: [
                    if (budgets.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Text('No budgets set yet', 
                            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
                        ),
                      )
                    else
                      ...budgets.asMap().entries.map((entry) {
                        final i = entry.key;
                        final b = entry.value;
                        return Column(
                          children: [
                            _TapTile(
                              icon: Icons.pie_chart_outline_rounded,
                              iconColor: cs.secondary,
                              title: b.category,
                              trailing: '${settings.currencySymbol}${b.monthlyLimit.toStringAsFixed(0)}',
                              onTap: () => _showBudgetDialog(context, ref, b),
                            ),
                            if (i < budgets.length - 1) _Divider(),
                          ],
                        );
                      }),
                  ]),
                  loading: () => const Center(child: LinearProgressIndicator()),
                  error: (err, stack) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 24),

                // ── API Key ────────────────────────────────────────────────
                _SectionHeader(title: 'API Key'),
                const SizedBox(height: 12),
                _SettingsCard(children: [
                  Padding(
                    padding: const EdgeInsets.all(4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(Icons.key_rounded, color: cs.primary, size: 20),
                          const SizedBox(width: 8),
                          Text('Gemini API Key', style: Theme.of(context).textTheme.titleMedium),
                        ]),
                        const SizedBox(height: 8),
                        Text(
                          'Stored securely on device. Never sent to our servers.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _keyController,
                          obscureText: !_keyVisible,
                          decoration: InputDecoration(
                            hintText: 'Enter API Key',
                            filled: true,
                            fillColor: cs.surfaceContainerLow,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            suffixIcon: IconButton(
                              icon: Icon(_keyVisible ? Icons.visibility_off : Icons.visibility, color: cs.outline),
                              onPressed: () => setState(() => _keyVisible = !_keyVisible),
                            ),
                          ),
                        ),
                        if (_keyStatus != null) ...[
                          const SizedBox(height: 8),
                          Row(children: [
                            Icon(
                              _keyStatus == 'ok' ? Icons.check_circle_rounded : Icons.cancel_rounded,
                              color: _keyStatus == 'ok' ? Colors.green : cs.error,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _keyStatus == 'ok' ? 'Key works! AI is ready.' : 'Key failed. Check and retry.',
                              style: TextStyle(
                                color: _keyStatus == 'ok' ? Colors.green : cs.error,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ]),
                        ],
                        const SizedBox(height: 12),
                        Row(children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isTestingKey ? null : _testKey,
                              icon: _isTestingKey
                                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Icon(Icons.wifi_tethering_rounded),
                              label: Text(_isTestingKey ? 'Testing...' : 'Test Key'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: cs.primary,
                                side: BorderSide(color: cs.primary.withValues(alpha: 0.4)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _saveKey,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: cs.primaryContainer,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: const Text('Save Key', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ]),
                      ],
                    ),
                  ),
                ]),
                const SizedBox(height: 24),


                // ── Appearance ────────────────────────────────────────────
                _SectionHeader(title: 'Appearance'),
                const SizedBox(height: 12),
                _SettingsCard(children: [
                  _ToggleTile(
                    icon: Icons.dark_mode_rounded,
                    iconColor: const Color(0xFF6A4FCA),
                    title: 'Dark Mode',
                    subtitle: settings.isDarkMode ? 'Currently dark' : 'Currently light',
                    value: settings.isDarkMode,
                    onChanged: (v) => ref.read(settingsProvider.notifier).setDarkMode(v),
                  ),
                ]),
                const SizedBox(height: 16),

                // ── Regional ──────────────────────────────────────────────
                _SectionHeader(title: 'Regional'),
                const SizedBox(height: 12),
                _SettingsCard(children: [
                  _TapTile(
                    icon: Icons.attach_money_rounded,
                    iconColor: Colors.green,
                    title: 'Currency',
                    trailing: '${settings.currency} (${settings.currencySymbol})',
                    onTap: _showCurrencyPicker,
                  ),
                ]),
                const SizedBox(height: 24),

                // ── App Info ──────────────────────────────────────────────
                _SectionHeader(title: 'About'),
                const SizedBox(height: 12),
                _SettingsCard(children: [
                  _InfoTile(icon: Icons.info_outline_rounded, iconColor: cs.primary, title: 'Version', value: '1.0.0'),
                  _Divider(),
                  _InfoTile(icon: Icons.security_rounded, iconColor: cs.primary, title: 'Privacy', value: 'Data stays on device'),
                ]),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Currency Picker ──────────────────────────────────────────────────────────

class _CurrencyPickerSheet extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final current = ref.watch(settingsProvider).currency;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 5, decoration: BoxDecoration(color: cs.outline.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(10))),
          const SizedBox(height: 20),
          Text('Select Currency', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 20),
          ...kSupportedCurrencies.map((c) => ListTile(
            leading: Text(c['symbol']!, style: const TextStyle(fontSize: 22)),
            title: Text(c['name']!),
            subtitle: Text(c['code']!),
            trailing: current == c['code'] ? Icon(Icons.check_circle_rounded, color: cs.primary) : null,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onTap: () => Navigator.pop(context, c),
          )),
        ],
      ),
    );
  }
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(children: children),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({required this.icon, required this.iconColor, required this.title, required this.subtitle, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            Text(subtitle, style: Theme.of(context).textTheme.labelMedium),
          ],
        )),
        Switch(value: value, onChanged: onChanged, activeThumbColor: cs.primary),
      ]),
    );
  }
}

class _TapTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String trailing;
  final VoidCallback onTap;

  const _TapTile({required this.icon, required this.iconColor, required this.title, required this.trailing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
          Text(trailing, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.primary)),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right_rounded, color: cs.outline, size: 20),
        ]),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  const _InfoTile({required this.icon, required this.iconColor, required this.title, required this.value});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
        Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
      ]),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Divider(
    height: 1,
    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
  );
}
