class Asset {
  final String id;
  final String userId;
  final String name;
  final double value;
  final String type; // vehicle, real_estate, other
  final bool isTaxable;
  final DateTime createdAt;

  Asset({
    required this.id,
    required this.userId,
    required this.name,
    required this.value,
    this.type = 'other',
    this.isTaxable = true,
    required this.createdAt,
  });

  factory Asset.fromJson(Map<String, dynamic> json) {
    return Asset(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      value: (json['value'] as num).toDouble(),
      type: json['type'] ?? 'other',
      isTaxable: json['is_taxable'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'value': value,
      'type': type,
      'is_taxable': isTaxable,
    };
  }
}
