import 'package:uuid/uuid.dart';

class WalletModel {
  final String id;
  final String name;
  final String emoji;
  final String colorHex;
  final DateTime createdAt;

  WalletModel({
    String? id,
    required this.name,
    this.emoji = '💰',
    this.colorHex = '#004D43',
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'colorHex': colorHex,
        'createdAt': createdAt.toIso8601String(),
      };

  factory WalletModel.fromMap(Map<String, Object?> map) => WalletModel(
        id: map['id'] as String,
        name: map['name'] as String,
        emoji: (map['emoji'] as String?) ?? '💰',
        colorHex: (map['colorHex'] as String?) ?? '#004D43',
        createdAt: DateTime.parse(map['createdAt'] as String),
      );

  WalletModel copyWith({
    String? name,
    String? emoji,
    String? colorHex,
  }) =>
      WalletModel(
        id: id,
        name: name ?? this.name,
        emoji: emoji ?? this.emoji,
        colorHex: colorHex ?? this.colorHex,
        createdAt: createdAt,
      );
}
