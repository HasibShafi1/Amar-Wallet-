import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:io';

void main() async {
  final apiKey = Platform.environment['GEMINI_API_KEY'];
  if (apiKey == null) {
    print('No API key');
    return;
  }

  final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
  final text = 'lent 500 to rohan';
  final prompt = '''
You are a smart financial assistant. Parse the following text and return ALL financial actions as a JSON array.
The text may be in English OR Bangla (বাংলা). Parse both correctly.
Each object MUST have an "intentType" field.

intentType values:
- "expense": money spent. Include: item (string), amount (number), category (one of: Food, Transport, Shopping, Groceries, Entertainment, Housing, Utilities, Other)
- "income": money received. Include: source (one of: Salary, Freelance, Business, Other), amount (number), description (string)
- "lent": money you gave to someone as a loan (ধার দেওয়া). Include: person (string), amount (number), note (string, optional)
- "borrowed": money you took from someone as a loan (ধার নেওয়া). Include: person (string), amount (number), note (string, optional)

Examples:
Input: "lunch 200 and bus 50"
Output: [{"intentType":"expense","item":"lunch","amount":200,"category":"Food"},{"intentType":"expense","item":"bus fare","amount":50,"category":"Transport"}]

Input: "I lent Rahim 1000 and earned 5000 from freelance"
Output: [{"intentType":"lent","person":"Rahim","amount":1000,"note":""},{"intentType":"income","source":"Freelance","amount":5000,"description":"freelance work"}]

Input: "I borrowed 500 from Karim"
Output: [{"intentType":"borrowed","person":"Karim","amount":500,"note":""}]

Input: "ভাত ২০০ আর রিকশা ৫০"
Output: [{"intentType":"expense","item":"ভাত","amount":200,"category":"Food"},{"intentType":"expense","item":"রিকশা","amount":50,"category":"Transport"}]

Input: "রহিমকে ১০০০ টাকা ধার দিলাম"
Output: [{"intentType":"lent","person":"রহিম","amount":1000,"note":""}]

Input: "করিমের কাছ থেকে ৩০০ টাকা ধার নিলাম"
Output: [{"intentType":"borrowed","person":"করিম","amount":300,"note":""}]

Text: "\$text"

Return ONLY a valid JSON array. No markdown, no explanation.
''';

  final response = await model.generateContent([Content.text(prompt)]);
  print('Result: \${response.text}');
}
