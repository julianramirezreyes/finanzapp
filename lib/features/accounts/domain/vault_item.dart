class VaultItem {
  final String id;
  final String accountId;
  final String title;
  final String data; // JSON string
  final bool isCard;
  final DateTime createdAt;

  VaultItem({
    required this.id,
    required this.accountId,
    required this.title,
    required this.data,
    required this.isCard,
    required this.createdAt,
  });

  factory VaultItem.fromJson(Map<String, dynamic> json) {
    return VaultItem(
      id: json['id'],
      accountId: json['account_id'],
      title: json['title'],
      data: json['data'],
      isCard: json['is_card'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
