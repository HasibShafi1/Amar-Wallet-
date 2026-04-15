class TagModel {
  final String name;
  final String colorHex;

  const TagModel({
    required this.name,
    this.colorHex = '#00897B',
  });

  Map<String, Object?> toMap() => {
        'name': name,
        'colorHex': colorHex,
      };

  factory TagModel.fromMap(Map<String, Object?> map) => TagModel(
        name: map['name'] as String,
        colorHex: (map['colorHex'] as String?) ?? '#00897B',
      );
}
