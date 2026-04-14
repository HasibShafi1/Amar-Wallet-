import 'package:uuid/uuid.dart';

class ExpenseModel {
  final String id;
  final double amount;
  final String category;
  final String description; // Mapped from 'item' in prompt
  final DateTime date;
  final DateTime createdAt;

  ExpenseModel({
    String? id,
    required this.amount,
    required this.category,
    required this.description,
    required this.date,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'amount': amount,
      'category': category,
      'description': description,
      'date': date.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ExpenseModel.fromMap(Map<String, Object?> map) {
    return ExpenseModel(
      id: map['id'] as String,
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] as String,
      description: map['description'] as String,
      date: DateTime.parse(map['date'] as String),
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  ExpenseModel copyWith({
    String? id,
    double? amount,
    String? category,
    String? description,
    DateTime? date,
    DateTime? createdAt,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      description: description ?? this.description,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
