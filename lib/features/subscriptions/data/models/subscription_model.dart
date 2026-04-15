import 'package:uuid/uuid.dart';

class SubscriptionModel {
  final String id;
  final String name;
  final double amount;
  final String frequency; // 'monthly' | 'yearly' | 'weekly'
  final String category;
  final DateTime startDate;
  final DateTime? nextDueDate;
  final bool isActive;
  final String icon;

  SubscriptionModel({
    String? id,
    required this.name,
    required this.amount,
    required this.frequency,
    this.category = 'Utilities',
    required this.startDate,
    DateTime? nextDueDate,
    this.isActive = true,
    this.icon = '🔄',
  })  : id = id ?? const Uuid().v4(),
        nextDueDate = nextDueDate ?? _calcNextDue(startDate, frequency);

  static DateTime _calcNextDue(DateTime start, String freq) {
    final now = DateTime.now();
    var next = start;
    while (next.isBefore(now)) {
      switch (freq) {
        case 'weekly':
          next = next.add(const Duration(days: 7));
        case 'yearly':
          next = DateTime(next.year + 1, next.month, next.day);
        default: // monthly
          next = DateTime(next.year, next.month + 1, next.day);
      }
    }
    return next;
  }

  double get monthlyCost {
    switch (frequency) {
      case 'weekly':
        return amount * 4.33;
      case 'yearly':
        return amount / 12;
      default:
        return amount;
    }
  }

  bool get isDueSoon {
    if (nextDueDate == null) return false;
    return nextDueDate!.difference(DateTime.now()).inDays <= 3;
  }

  bool get isOverdue {
    if (nextDueDate == null) return false;
    return nextDueDate!.isBefore(DateTime.now());
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'amount': amount,
        'frequency': frequency,
        'category': category,
        'startDate': startDate.toIso8601String(),
        'nextDueDate': nextDueDate?.toIso8601String(),
        'isActive': isActive ? 1 : 0,
        'icon': icon,
      };

  factory SubscriptionModel.fromMap(Map<String, Object?> map) =>
      SubscriptionModel(
        id: map['id'] as String,
        name: map['name'] as String,
        amount: (map['amount'] as num).toDouble(),
        frequency: map['frequency'] as String,
        category: (map['category'] as String?) ?? 'Utilities',
        startDate: DateTime.parse(map['startDate'] as String),
        nextDueDate: map['nextDueDate'] != null
            ? DateTime.tryParse(map['nextDueDate'] as String)
            : null,
        isActive: (map['isActive'] as int?) == 1,
        icon: (map['icon'] as String?) ?? '🔄',
      );

  SubscriptionModel copyWith({
    String? name,
    double? amount,
    String? frequency,
    String? category,
    DateTime? startDate,
    DateTime? nextDueDate,
    bool? isActive,
    String? icon,
  }) =>
      SubscriptionModel(
        id: id,
        name: name ?? this.name,
        amount: amount ?? this.amount,
        frequency: frequency ?? this.frequency,
        category: category ?? this.category,
        startDate: startDate ?? this.startDate,
        nextDueDate: nextDueDate ?? this.nextDueDate,
        isActive: isActive ?? this.isActive,
        icon: icon ?? this.icon,
      );
}
