import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// ─── Settings State ─────────────────────────────────────────────────────────

class AppSettings {
  final bool isDarkMode;
  final String currency;
  final String currencySymbol;
  final bool aiEnabled;
  final String aiProvider;
  final double dailyGoal;
  // Profile
  final String userName;
  final String userAvatar;
  final String userEmail;
  // Voice
  final String voiceLanguage; // 'en_US' | 'bn_BD'
  // Notifications
  final bool notifyDailySummary;
  final bool notifyBudgetAlerts;
  final bool notifyGoalReminders;
  final bool notifySubscriptionDue;
  final int dailySummaryHour; // 0-23

  const AppSettings({
    this.isDarkMode = false,
    this.currency = 'USD',
    this.currencySymbol = '\$',
    this.aiEnabled = true,
    this.aiProvider = 'Gemini',
    this.dailyGoal = 200.0,
    this.userName = '',
    this.userAvatar = '👤',
    this.userEmail = '',
    this.voiceLanguage = 'en_US',
    this.notifyDailySummary = false,
    this.notifyBudgetAlerts = true,
    this.notifyGoalReminders = true,
    this.notifySubscriptionDue = true,
    this.dailySummaryHour = 21,
  });

  AppSettings copyWith({
    bool? isDarkMode,
    String? currency,
    String? currencySymbol,
    bool? aiEnabled,
    String? aiProvider,
    double? dailyGoal,
    String? userName,
    String? userAvatar,
    String? userEmail,
    String? voiceLanguage,
    bool? notifyDailySummary,
    bool? notifyBudgetAlerts,
    bool? notifyGoalReminders,
    bool? notifySubscriptionDue,
    int? dailySummaryHour,
  }) {
    return AppSettings(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      currency: currency ?? this.currency,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      aiEnabled: aiEnabled ?? this.aiEnabled,
      aiProvider: aiProvider ?? this.aiProvider,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      userEmail: userEmail ?? this.userEmail,
      voiceLanguage: voiceLanguage ?? this.voiceLanguage,
      notifyDailySummary: notifyDailySummary ?? this.notifyDailySummary,
      notifyBudgetAlerts: notifyBudgetAlerts ?? this.notifyBudgetAlerts,
      notifyGoalReminders: notifyGoalReminders ?? this.notifyGoalReminders,
      notifySubscriptionDue: notifySubscriptionDue ?? this.notifySubscriptionDue,
      dailySummaryHour: dailySummaryHour ?? this.dailySummaryHour,
    );
  }
}

// ─── Supported Currencies ────────────────────────────────────────────────────

const List<Map<String, String>> kSupportedCurrencies = [
  {'name': 'US Dollar', 'code': 'USD', 'symbol': '\$'},
  {'name': 'Euro', 'code': 'EUR', 'symbol': '€'},
  {'name': 'British Pound', 'code': 'GBP', 'symbol': '£'},
  {'name': 'Japanese Yen', 'code': 'JPY', 'symbol': '¥'},
  {'name': 'Bangladeshi Taka', 'code': 'BDT', 'symbol': '৳'},
  {'name': 'Indian Rupee', 'code': 'INR', 'symbol': '₹'},
  {'name': 'Canadian Dollar', 'code': 'CAD', 'symbol': 'CA\$'},
  {'name': 'Australian Dollar', 'code': 'AUD', 'symbol': 'A\$'},
];

// ─── Notifier ────────────────────────────────────────────────────────────────

class SettingsNotifier extends Notifier<AppSettings> {
  static const _storage = FlutterSecureStorage();

  @override
  AppSettings build() {
    _load();
    return const AppSettings();
  }

  Future<void> _load() async {
    final isDark = await _storage.read(key: 'isDarkMode') == 'true';
    final currency = await _storage.read(key: 'currency') ?? 'USD';
    final symbol = await _storage.read(key: 'currencySymbol') ?? '\$';
    final aiEnabled = (await _storage.read(key: 'aiEnabled')) != 'false';
    final aiProv = await _storage.read(key: 'aiProvider') ?? 'Gemini';
    final goalStr = await _storage.read(key: 'dailyGoal');
    final dailyGoal = double.tryParse(goalStr ?? '') ?? 200.0;
    // Profile
    final userName = await _storage.read(key: 'userName') ?? '';
    final userAvatar = await _storage.read(key: 'userAvatar') ?? '👤';
    final userEmail = await _storage.read(key: 'userEmail') ?? '';
    // Voice
    final voiceLang = await _storage.read(key: 'voiceLanguage') ?? 'en_US';
    // Notifications
    final notDS = (await _storage.read(key: 'notifyDailySummary')) == 'true';
    final notBA = (await _storage.read(key: 'notifyBudgetAlerts')) != 'false';
    final notGR = (await _storage.read(key: 'notifyGoalReminders')) != 'false';
    final notSD = (await _storage.read(key: 'notifySubscriptionDue')) != 'false';
    final dsHour = int.tryParse(await _storage.read(key: 'dailySummaryHour') ?? '') ?? 21;

    state = AppSettings(
      isDarkMode: isDark,
      currency: currency,
      currencySymbol: symbol,
      aiEnabled: aiEnabled,
      aiProvider: aiProv,
      dailyGoal: dailyGoal,
      userName: userName,
      userAvatar: userAvatar,
      userEmail: userEmail,
      voiceLanguage: voiceLang,
      notifyDailySummary: notDS,
      notifyBudgetAlerts: notBA,
      notifyGoalReminders: notGR,
      notifySubscriptionDue: notSD,
      dailySummaryHour: dsHour,
    );
  }

  Future<void> setDarkMode(bool val) async {
    await _storage.write(key: 'isDarkMode', value: val.toString());
    state = state.copyWith(isDarkMode: val);
  }

  Future<void> setCurrency(String code, String symbol) async {
    await _storage.write(key: 'currency', value: code);
    await _storage.write(key: 'currencySymbol', value: symbol);
    state = state.copyWith(currency: code, currencySymbol: symbol);
  }

  Future<void> setAiEnabled(bool val) async {
    await _storage.write(key: 'aiEnabled', value: val.toString());
    state = state.copyWith(aiEnabled: val);
  }

  Future<void> setAiProvider(String provider) async {
    await _storage.write(key: 'aiProvider', value: provider);
    state = state.copyWith(aiProvider: provider);
  }

  Future<void> setDailyGoal(double goal) async {
    await _storage.write(key: 'dailyGoal', value: goal.toString());
    state = state.copyWith(dailyGoal: goal);
  }

  // Profile
  Future<void> setUserName(String name) async {
    await _storage.write(key: 'userName', value: name);
    state = state.copyWith(userName: name);
  }

  Future<void> setUserAvatar(String emoji) async {
    await _storage.write(key: 'userAvatar', value: emoji);
    state = state.copyWith(userAvatar: emoji);
  }

  Future<void> setUserEmail(String email) async {
    await _storage.write(key: 'userEmail', value: email);
    state = state.copyWith(userEmail: email);
  }

  // Voice
  Future<void> setVoiceLanguage(String locale) async {
    await _storage.write(key: 'voiceLanguage', value: locale);
    state = state.copyWith(voiceLanguage: locale);
  }

  // Notifications
  Future<void> setNotifyDailySummary(bool val) async {
    await _storage.write(key: 'notifyDailySummary', value: val.toString());
    state = state.copyWith(notifyDailySummary: val);
  }

  Future<void> setNotifyBudgetAlerts(bool val) async {
    await _storage.write(key: 'notifyBudgetAlerts', value: val.toString());
    state = state.copyWith(notifyBudgetAlerts: val);
  }

  Future<void> setNotifyGoalReminders(bool val) async {
    await _storage.write(key: 'notifyGoalReminders', value: val.toString());
    state = state.copyWith(notifyGoalReminders: val);
  }

  Future<void> setNotifySubscriptionDue(bool val) async {
    await _storage.write(key: 'notifySubscriptionDue', value: val.toString());
    state = state.copyWith(notifySubscriptionDue: val);
  }

  Future<void> setDailySummaryHour(int hour) async {
    await _storage.write(key: 'dailySummaryHour', value: hour.toString());
    state = state.copyWith(dailySummaryHour: hour);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(() {
  return SettingsNotifier();
});

// Convenience provider for ThemeMode
final themeModeProvider = Provider<ThemeMode>((ref) {
  final settings = ref.watch(settingsProvider);
  return settings.isDarkMode ? ThemeMode.dark : ThemeMode.light;
});
