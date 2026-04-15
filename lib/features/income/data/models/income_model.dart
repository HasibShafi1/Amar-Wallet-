import 'package:uuid/uuid.dart';

class IncomeModel {
  final String id;
  final double amount;
  final String source; // Salary | Freelance | Business | Other
  final String description;
  final DateTime date;

  IncomeModel({
    String? id,
    required this.amount,
    required this.source,
    required this.description,
    required this.date,
  }) : id = id ?? const Uuid().v4();

  Map<String, Object?> toMap() => {
        'id': id,
        'amount': amount,
        'source': source,
        'description': description,
        'date': date.toIso8601String(),
      };

  factory IncomeModel.fromMap(Map<String, Object?> map) => IncomeModel(
        id: map['id'] as String,
        amount: (map['amount'] as num).toDouble(),
        source: map['source'] as String,
        description: map['description'] as String,
        date: DateTime.parse(map['date'] as String),
      );

  IncomeModel copyWith({
    double? amount,
    String? source,
    String? description,
    DateTime? date,
  }) =>
      IncomeModel(
        id: id,
        amount: amount ?? this.amount,
        source: source ?? this.source,
        description: description ?? this.description,
        date: date ?? this.date,
      );
}
