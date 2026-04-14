import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../expenses/data/models/expense_model.dart';

final aiServiceProvider = Provider<AIService>((ref) {
  return AIService();
});

class AIService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _apiKeyKey = 'gemini_api_key';

  Future<void> saveApiKey(String apiKey) async {
    await _storage.write(key: _apiKeyKey, value: apiKey);
  }

  Future<String?> getApiKey() async {
    return await _storage.read(key: _apiKeyKey);
  }

  Future<List<ExpenseModel>> parseExpenses(String textInput, {int retryCount = 1}) async {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('API Key is missing. Please add it in Settings.');
    }

    final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);

    final prompt = '''
You are an expense parser.
Extract all expenses from the given sentence.
Return ONLY valid JSON.

Each object must contain:
item as string
amount as number
category as one of Food, Transport, Shopping, Groceries, Entertainment, Other

Sentence:
"$textInput"

Return format:
[
  { "item": "", "amount": 0, "category": "" }
]
''';

    try {
      final response = await model.generateContent([Content.text(prompt)]);
      final resultText = response.text;
      
      if (resultText == null) throw Exception('Null response from Gemini');

      final cleanJson = resultText.replaceAll('```json', '').replaceAll('```', '').trim();
      final List<dynamic> jsonList = jsonDecode(cleanJson);
      
      return jsonList.map((item) => ExpenseModel(
        amount: (item['amount'] as num).toDouble(),
        category: item['category'] as String,
        description: item['item'] as String,
        date: DateTime.now(),
      )).toList();

    } catch (e) {
      if (retryCount > 0) {
        return await parseExpenses(textInput, retryCount: retryCount - 1);
      } else {
        return _simpleFallbackParsing(textInput);
      }
    }
  }

  List<ExpenseModel> _simpleFallbackParsing(String text) {
    final words = text.split(' ');
    double amount = 0.0;
    for (var word in words) {
      final val = double.tryParse(word.replaceAll(RegExp(r'[^0-9.]'), ''));
      if (val != null) {
        amount = val;
        break;
      }
    }
    
    return [
      ExpenseModel(
        amount: amount,
        category: 'Other',
        description: text.length > 50 ? text.substring(0, 50) : text,
        date: DateTime.now(),
      )
    ];
  }

  Future<List<String>> getInsights(List<ExpenseModel> expenses) async {
    if (expenses.isEmpty) return ["Add some expenses to get insights."];
    
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('API Key is missing');
    }

    final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
    
    final expenseJson = expenses.map((e) => {
      "item": e.description,
      "amount": e.amount,
      "category": e.category
    }).toList();

    final prompt = '''
Analyze the following expenses and generate 3 short financial tips.
Keep them practical and concise.
Return ONLY valid JSON in this format:
{
  "insights": [
    "string",
    "string",
    "string"
  ]
}

Expenses:
${jsonEncode(expenseJson)}
''';

    try {
      final response = await model.generateContent([Content.text(prompt)]);
      final resultText = response.text;
      if (resultText == null) return [];

      final cleanJson = resultText.replaceAll('```json', '').replaceAll('```', '').trim();
      final Map<String, dynamic> jsonResponse = jsonDecode(cleanJson);
      final List<dynamic> insights = jsonResponse['insights'];
      
      return insights.map((e) => e.toString()).toList();
    } catch (e) {
      return ["Track your daily limits.", "Review recurring expenses regularly."];
    }
  }
}
