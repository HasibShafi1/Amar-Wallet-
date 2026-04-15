import 'package:uuid/uuid.dart';

class LedgerModel {
  final String id;
  final String type; // 'lent' | 'borrowed'
  final String person;
  final double amount;
  final String note;
  final DateTime date;
  final bool isPaid;

  LedgerModel({
    String? id,
    required this.type,
    required this.person,
    required this.amount,
    this.note = '',
    required this.date,
    this.isPaid = false,
  }) : id = id ?? const Uuid().v4();

  Map<String, Object?> toMap() => {
        'id': id,
        'type': type,
        'person': person,
        'amount': amount,
        'note': note,
        'date': date.toIso8601String(),
        'isPaid': isPaid ? 1 : 0,
      };

  factory LedgerModel.fromMap(Map<String, Object?> map) => LedgerModel(
        id: map['id'] as String,
        type: map['type'] as String,
        person: map['person'] as String,
        amount: (map['amount'] as num).toDouble(),
        note: (map['note'] as String?) ?? '',
        date: DateTime.parse(map['date'] as String),
        isPaid: (map['isPaid'] as int) == 1,
      );

  LedgerModel copyWith({
    String? type,
    String? person,
    double? amount,
    String? note,
    DateTime? date,
    bool? isPaid,
  }) =>
      LedgerModel(
        id: id,
        type: type ?? this.type,
        person: person ?? this.person,
        amount: amount ?? this.amount,
        note: note ?? this.note,
        date: date ?? this.date,
        isPaid: isPaid ?? this.isPaid,
      );
}
