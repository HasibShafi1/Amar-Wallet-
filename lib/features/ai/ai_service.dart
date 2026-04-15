import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../expenses/data/models/expense_model.dart';
import '../income/data/models/income_model.dart';
import '../ledger/data/models/ledger_model.dart';
import '../../core/utils/category_engine.dart';

final aiServiceProvider = Provider<AIService>((ref) => AIService());

// ─── Parsed Voice Action ──────────────────────────────────────────────────────
sealed class VoiceAction {}

class ExpenseAction extends VoiceAction {
  final List<ExpenseModel> expenses;
  ExpenseAction(this.expenses);
}

class IncomeAction extends VoiceAction {
  final IncomeModel income;
  IncomeAction(this.income);
}

class LedgerAction extends VoiceAction {
  final LedgerModel entry;
  LedgerAction(this.entry);
}

// ─── Service ──────────────────────────────────────────────────────────────────
class AIService {
  static const _storage = FlutterSecureStorage();
  static const _apiKeyKey = 'gemini_api_key';

  Future<void> saveApiKey(String key) async =>
      _storage.write(key: _apiKeyKey, value: key);

  Future<String?> getApiKey() async => _storage.read(key: _apiKeyKey);

  // ── Parse all intents from voice input ──────────────────────────────────────
  Future<List<VoiceAction>> parseVoiceInput(String text) async {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      return _fallbackParse(text);
    }

    final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
    final prompt = '''
You are a smart financial assistant. Parse the following text and return ALL financial actions as a JSON array.
The text may be in English OR Bangla (বাংলা). Parse both correctly.
Each object MUST have an "intentType" field.

intentType values:
- "expense": money spent. Include: item (string), amount (number), category (one of: Food, Transport, Shopping, Groceries, Entertainment, Housing, Utilities, Other)
- "income": money received. Include: source (one of: Salary, Freelance, Business, Other), amount (number), description (string)
- "lent": money given to someone. Include: person (string), amount (number), note (string, optional)
- "borrowed": money borrowed from someone. Include: person (string), amount (number), note (string, optional)

Examples:
Input: "lunch 200 and bus 50"
Output: [{"intentType":"expense","item":"lunch","amount":200,"category":"Food"},{"intentType":"expense","item":"bus fare","amount":50,"category":"Transport"}]

Input: "I gave Rahim 1000 and earned 5000 from freelance"
Output: [{"intentType":"lent","person":"Rahim","amount":1000,"note":""},{"intentType":"income","source":"Freelance","amount":5000,"description":"freelance work"}]

Input: "I borrowed 500 from Karim"
Output: [{"intentType":"borrowed","person":"Karim","amount":500,"note":""}]

Input: "ভাত ২০০ আর রিকশা ৫০"
Output: [{"intentType":"expense","item":"ভাত","amount":200,"category":"Food"},{"intentType":"expense","item":"রিকশা","amount":50,"category":"Transport"}]

Input: "রহিমকে ১০০০ টাকা দিলাম"
Output: [{"intentType":"lent","person":"রহিম","amount":1000,"note":""}]

Text: "$text"

Return ONLY a valid JSON array. No markdown, no explanation.
''';

    try {
      final response = await model.generateContent([Content.text(prompt)]);
      final raw = response.text ?? '';
      final jsonStart = raw.indexOf('[');
      final jsonEnd = raw.lastIndexOf(']');
      if (jsonStart == -1 || jsonEnd == -1) throw Exception('Invalid AI response');
      final clean = raw.substring(jsonStart, jsonEnd + 1);
      final List<dynamic> list = jsonDecode(clean);
      return _mapToActions(list);
    } catch (_) {
      try {
        // One retry
        final response = await model
            .generateContent([Content.text(prompt)]);
        final raw = response.text ?? '';
        final clean =
            raw.replaceAll('```json', '').replaceAll('```', '').trim();
        final List<dynamic> list = jsonDecode(clean);
        return _mapToActions(list);
      } catch (_) {
        return _fallbackParse(text);
      }
    }
  }

  List<VoiceAction> _mapToActions(List<dynamic> list) {
    final engine = CategoryEngine.instance;
    final results = <VoiceAction>[];
    final now = DateTime.now();

    for (final item in list) {
      final intentType = item['intentType'] as String? ?? 'expense';
      switch (intentType) {
        case 'income':
          results.add(IncomeAction(IncomeModel(
            amount: (item['amount'] as num).toDouble(),
            source: item['source'] as String? ?? 'Other',
            description: item['description'] as String? ?? 'Income',
            date: now,
          )));
        case 'lent':
          results.add(LedgerAction(LedgerModel(
            type: 'lent',
            person: item['person'] as String? ?? 'Unknown',
            amount: (item['amount'] as num).toDouble(),
            note: item['note'] as String? ?? '',
            date: now,
          )));
        case 'borrowed':
          results.add(LedgerAction(LedgerModel(
            type: 'borrowed',
            person: item['person'] as String? ?? 'Unknown',
            amount: (item['amount'] as num).toDouble(),
            note: item['note'] as String? ?? '',
            date: now,
          )));
        default: // expense
          final description = item['item'] as String? ?? 'Expense';
          final aiCategory = item['category'] as String? ?? 'Other';
          final category = engine.resolveCategory(description, aiCategory);
          results.add(ExpenseAction([
            ExpenseModel(
              amount: (item['amount'] as num).toDouble(),
              category: category,
              description: description,
              date: now,
            )
          ]));
      }
    }

    // Merge consecutive ExpenseActions into one
    final merged = <VoiceAction>[];
    final pendingExpenses = <ExpenseModel>[];
    for (final action in results) {
      if (action is ExpenseAction) {
        pendingExpenses.addAll(action.expenses);
      } else {
        if (pendingExpenses.isNotEmpty) {
          merged.add(ExpenseAction(List.from(pendingExpenses)));
          pendingExpenses.clear();
        }
        merged.add(action);
      }
    }
    if (pendingExpenses.isNotEmpty) {
      merged.add(ExpenseAction(pendingExpenses));
    }
    return merged;
  }

  List<VoiceAction> _fallbackParse(String text) {
    // Regex: find numbers (both English and Bangla digits)
    // Convert Bangla digits to English first
    final converted = _convertBanglaDigits(text);
    final pattern = RegExp(r'(\d+(?:\.\d+)?)', caseSensitive: false);
    final matches = pattern.allMatches(converted);
    if (matches.isEmpty) return [];

    final expenses = <ExpenseModel>[];
    final engine = CategoryEngine.instance;

    for (final match in matches) {
      final amount = double.tryParse(match.group(0)!) ?? 0;
      if (amount <= 0) continue;
      final description = converted.substring(
              match.start > 15 ? match.start - 15 : 0, match.start)
          .trim()
          .split(' ')
          .lastWhere((w) => w.isNotEmpty, orElse: () => 'Expense');
      final category = engine.detect(description) ?? 'Other';
      expenses.add(ExpenseModel(
        amount: amount,
        category: category,
        description: description,
        date: DateTime.now(),
      ));
    }

    return expenses.isEmpty ? [] : [ExpenseAction(expenses)];
  }

  /// Convert Bangla digits (০-৯) to English digits (0-9)
  String _convertBanglaDigits(String text) {
    const bangla = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    var result = text;
    for (int i = 0; i < bangla.length; i++) {
      result = result.replaceAll(bangla[i], '$i');
    }
    return result;
  }

  // ── Legacy: kept for compatibility ──────────────────────────────────────────
  Future<List<ExpenseModel>> parseExpenses(String text) async {
    final actions = await parseVoiceInput(text);
    final expenses = <ExpenseModel>[];
    for (final a in actions) {
      if (a is ExpenseAction) expenses.addAll(a.expenses);
    }
    return expenses;
  }

  // ── Contextual AI Insights ───────────────────────────────────────────────────
  Future<List<String>> getInsights({
    required List<ExpenseModel> expenses,
    required List<IncomeModel> income,
    required Map<String, dynamic> budgets, // Category: limit
    required List<dynamic> goals, // Title: progress
  }) async {
    if (expenses.isEmpty && income.isEmpty) {
      return ['Add some transactions to get personalized AI insights.'];
    }

    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) throw Exception('API Key missing');

    final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);

    // Group by category
    final Map<String, double> byCategory = {};
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final lastWeekStart = weekStart.subtract(const Duration(days: 7));

    double thisWeekTotal = 0;
    double lastWeekTotal = 0;

    for (final e in expenses) {
      if (e.date.year == now.year && e.date.month == now.month) {
        byCategory[e.category] = (byCategory[e.category] ?? 0) + e.amount;
      }
      if (e.date.isAfter(weekStart)) {
        thisWeekTotal += e.amount;
      } else if (e.date.isAfter(lastWeekStart)) {
        lastWeekTotal += e.amount;
      }
    }

    final totalIncome = income.fold(0.0, (s, i) => s + i.amount);
    final totalSpent = expenses.fold(0.0, (s, e) => s + e.amount);

    final prompt = '''
You are a elite personal finance advisor. Analyze the following financial snapshot and provide 5 HIGH-VALUE, specific insights.

SNAPSHOT:
- Total Income: $totalIncome
- Total Expenses: $totalSpent
- Net Savings: ${totalIncome - totalSpent}
- This Week Spending: $thisWeekTotal (vs Last Week: $lastWeekTotal)
- Spending by Category (This Month): ${jsonEncode(byCategory)}
- Active Budgets: ${jsonEncode(budgets)}
- Financial Goals: ${jsonEncode(goals)}

INSIGHT RULES:
1. Be extremely specific. Use EXACT names and amounts from the data.
2. Compare spending to budgets (e.g. "You are at 85% of your \$500 Food budget").
3. Detect trends (e.g. "Transport costs are 20% higher than last week").
4. Provide 1 high-impact "Saving Tip" based on the highest category.
5. Provide 1 "Goal Encouragement" based on their goals progress.
6. Keep each insight concise (1-2 sentences).

Return ONLY this JSON (no markdown):
{"insights": ["string","string","string","string","string"]}
''';

    try {
      final response = await model.generateContent([Content.text(prompt)]);
      final raw = response.text ?? '';
      final jsonStart = raw.indexOf('{');
      final jsonEnd = raw.lastIndexOf('}');
      if (jsonStart == -1 || jsonEnd == -1) throw Exception('Invalid AI response');
      final clean = raw.substring(jsonStart, jsonEnd + 1);
      final Map<String, dynamic> json = jsonDecode(clean);
      return (json['insights'] as List).map((e) => e.toString()).toList();
    } catch (_) {
      return [
        'Your top spending category is ${byCategory.entries.reduce((a, b) => a.value > b.value ? a : b).key}.',
        'Track daily expenses to stay within budget.',
      ];
    }
  }
}
