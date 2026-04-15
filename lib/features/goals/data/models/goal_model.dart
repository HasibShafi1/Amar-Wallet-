import 'package:uuid/uuid.dart';

class GoalModel {
  final String id;
  final String title;
  final double targetAmount;
  final double savedAmount;
  final DateTime? deadline;
  final String emoji;
  final DateTime createdAt;

  GoalModel({
    String? id,
    required this.title,
    required this.targetAmount,
    this.savedAmount = 0,
    this.deadline,
    this.emoji = '🎯',
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  bool get isCompleted => savedAmount >= targetAmount;
  double get progress => (savedAmount / targetAmount).clamp(0.0, 1.0);
  double get remaining => (targetAmount - savedAmount).clamp(0, targetAmount);

  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'targetAmount': targetAmount,
        'savedAmount': savedAmount,
        'deadline': deadline?.toIso8601String(),
        'emoji': emoji,
        'createdAt': createdAt.toIso8601String(),
      };

  factory GoalModel.fromMap(Map<String, Object?> map) => GoalModel(
        id: map['id'] as String,
        title: map['title'] as String,
        targetAmount: (map['targetAmount'] as num).toDouble(),
        savedAmount: (map['savedAmount'] as num).toDouble(),
        deadline: map['deadline'] != null
            ? DateTime.tryParse(map['deadline'] as String)
            : null,
        emoji: (map['emoji'] as String?) ?? '🎯',
        createdAt: DateTime.parse(map['createdAt'] as String),
      );

  GoalModel copyWith({
    String? title,
    double? targetAmount,
    double? savedAmount,
    DateTime? deadline,
    String? emoji,
  }) =>
      GoalModel(
        id: id,
        title: title ?? this.title,
        targetAmount: targetAmount ?? this.targetAmount,
        savedAmount: savedAmount ?? this.savedAmount,
        deadline: deadline ?? this.deadline,
        emoji: emoji ?? this.emoji,
        createdAt: createdAt,
      );
}
