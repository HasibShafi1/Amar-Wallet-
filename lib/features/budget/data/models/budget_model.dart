class BudgetModel {
  final String category;
  final double monthlyLimit;

  const BudgetModel({required this.category, required this.monthlyLimit});

  Map<String, Object?> toMap() => {
        'category': category,
        'monthlyLimit': monthlyLimit,
      };

  factory BudgetModel.fromMap(Map<String, Object?> map) => BudgetModel(
        category: map['category'] as String,
        monthlyLimit: (map['monthlyLimit'] as num).toDouble(),
      );

  BudgetModel copyWith({double? monthlyLimit}) =>
      BudgetModel(category: category, monthlyLimit: monthlyLimit ?? this.monthlyLimit);
}
