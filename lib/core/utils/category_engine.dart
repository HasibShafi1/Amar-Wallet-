import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Maps user-spoken words to expense categories.
/// Decision chain: user overrides → keyword table → null (let AI decide)
class CategoryEngine {
  static final CategoryEngine instance = CategoryEngine._();
  CategoryEngine._();

  static const _storage = FlutterSecureStorage();
  static const _overridePrefix = 'cat_override_';

  final Map<String, String> _userOverrides = {};

  static const Map<String, List<String>> _keywords = {
    'Food': [
      'food', 'lunch', 'dinner', 'breakfast', 'brunch', 'rice', 'pizza',
      'burger', 'biryani', 'khana', 'khabar', 'chai', 'coffee', 'tea',
      'snack', 'cake', 'bread', 'noodles', 'pasta', 'sandwich', 'soup',
      'restaurant', 'cafe', 'dine', 'eat', 'meal', 'iftar', 'sehri',
      'roti', 'dal', 'curry', 'chicken', 'beef', 'fish', 'egg', 'paratha',
      'kebab', 'shawarma', 'fries', 'juice', 'drink', 'soda', 'water',
    ],
    'Transport': [
      'bus', 'rickshaw', 'uber', 'pathao', 'cng', 'taxi', 'auto',
      'fuel', 'petrol', 'diesel', 'train', 'ride', 'fare', 'ticket',
      'ferry', 'launch', 'metro', 'boat', 'car', 'bike', 'motorbike',
      'parking', 'toll', 'transport', 'vehicle',
    ],
    'Groceries': [
      'grocery', 'groceries', 'market', 'bazar', 'bazaar', 'vegetables',
      'veggies', 'egg', 'milk', 'fish', 'meat', 'oil', 'salt', 'sugar',
      'flour', 'atta', 'lentil', 'dal', 'onion', 'potato', 'tomato',
      'garlic', 'ginger', 'spice', 'rice bag', 'supermarket', 'shop',
    ],
    'Shopping': [
      'shirt', 'clothes', 'clothing', 'shoes', 'sneakers', 'pants',
      'dress', 'jacket', 'sari', 'saree', 'panjabi', 'amazon', 'daraz',
      'mall', 'purchase', 'bought', 'order', 'delivery', 'bag', 'wallet',
      'watch', 'glasses', 'accessories', 'gift', 'present',
    ],
    'Entertainment': [
      'movie', 'cinema', 'netflix', 'youtube', 'game', 'gaming', 'spotify',
      'concert', 'show', 'event', 'party', 'fun', 'outing', 'picnic',
      'sports', 'cricket', 'football', 'gym', 'fitness', 'subscription',
    ],
    'Housing': [
      'rent', 'house rent', 'bari bhara', 'electricity', 'gas', 'water bill',
      'maintenance', 'repair', 'plumber', 'paint', 'renovation', 'furniture',
      'appliance', 'fan', 'ac', 'fridge', 'cleaning',
    ],
    'Utilities': [
      'internet', 'wifi', 'broadband', 'sim', 'recharge', 'mobile bill',
      'phone bill', 'bkash', 'nagad', 'rocket', 'transfer', 'topup',
    ],
  };

  // ─── Bangla Keyword Mappings ──────────────────────────────────────────────
  static const Map<String, List<String>> _banglaKeywords = {
    'Food': [
      'ভাত', 'মাছ', 'খিচুড়ি', 'বিরিয়ানী', 'চা', 'নাস্তা', 'দুপুরের খাবার',
      'রাতের খাবার', 'সকালের নাস্তা', 'পিৎজা', 'বার্গার', 'রুটি', 'ডাল',
      'তরকারি', 'মুরগি', 'গরু', 'ডিম', 'পরাটা', 'কফি', 'জুস', 'পানি',
      'খাবার', 'রেস্টুরেন্ট', 'হোটেল', 'ইফতার', 'সেহরী',
    ],
    'Transport': [
      'রিকশা', 'বাস', 'সিএনজি', 'ট্রেন', 'ভাড়া', 'উবার', 'পাঠাও',
      'ট্যাক্সি', 'অটো', 'পেট্রোল', 'ডিজেল', 'গাড়ি', 'বাইক', 'পার্কিং',
      'টোল', 'যাতায়াত', 'লঞ্চ', 'ফেরি', 'মেট্রো',
    ],
    'Groceries': [
      'বাজার', 'সবজি', 'শাক', 'চাল', 'আটা', 'তেল', 'লবণ', 'চিনি',
      'মসলা', 'পেঁয়াজ', 'আলু', 'টমেটো', 'রসুন', 'আদা', 'ডাল',
      'সুপারমার্কেট', 'দোকান',
    ],
    'Shopping': [
      'জামা', 'কাপড়', 'জুতা', 'প্যান্ট', 'শাড়ি', 'পাঞ্জাবি',
      'কেনাকাটা', 'শপিং', 'অর্ডার', 'ডেলিভারি',
    ],
    'Entertainment': [
      'সিনেমা', 'মুভি', 'নেটফ্লিক্স', 'গেম', 'খেলা', 'ক্রিকেট',
      'ফুটবল', 'জিম', 'পার্টি', 'বেড়ানো', 'পিকনিক',
    ],
    'Housing': [
      'বাড়ি ভাড়া', 'ভাড়া', 'বিদ্যুৎ', 'গ্যাস', 'পানির বিল',
      'মেরামত', 'রং', 'আসবাবপত্র', 'ফ্যান', 'এসি', 'ফ্রিজ',
    ],
    'Utilities': [
      'ইন্টারনেট', 'ওয়াইফাই', 'রিচার্জ', 'মোবাইল বিল', 'ফোন বিল',
      'বিকাশ', 'নগদ', 'রকেট', 'ট্রান্সফার',
    ],
  };

  /// Load user-saved category overrides from secure storage
  Future<void> init() async {
    final all = await _storage.readAll();
    for (final entry in all.entries) {
      if (entry.key.startsWith(_overridePrefix)) {
        final keyword = entry.key.substring(_overridePrefix.length);
        _userOverrides[keyword] = entry.value;
      }
    }
  }

  /// Returns the best category for a description string, or null if unknown.
  String? detect(String description) {
    final lower = description.toLowerCase();

    // 1. User-learned overrides take highest priority
    for (final entry in _userOverrides.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }

    // 2. Built-in keyword table (English)
    for (final entry in _keywords.entries) {
      for (final kw in entry.value) {
        if (lower.contains(kw)) return entry.key;
      }
    }

    // 3. Bangla keyword table
    for (final entry in _banglaKeywords.entries) {
      for (final kw in entry.value) {
        if (description.contains(kw)) return entry.key;
      }
    }

    return null; // Let AI decide
  }

  /// Save a user correction: next time this keyword appears → use this category
  Future<void> saveOverride(String description, String category) async {
    // Extract meaningful keywords from the description
    final words = description.toLowerCase().split(RegExp(r'\s+'))
        .where((w) => w.length > 2)
        .toList();
    for (final word in words) {
      _userOverrides[word] = category;
      await _storage.write(key: '$_overridePrefix$word', value: category);
    }
  }

  /// Apply category to a list of expense maps from AI output.
  /// Overrides the AI's category if our engine is more confident.
  String resolveCategory(String description, String aiCategory) {
    return detect(description) ?? aiCategory;
  }
}
