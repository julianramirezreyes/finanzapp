import 'dart:convert';

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

  Map<String, dynamic> get parsedData {
    try {
      if (data.isEmpty) return {};
      return Map<String, dynamic>.from(jsonDecode(data));
    } catch (_) {
      return {};
    }
  }

  String get cardType => parsedData['card_type'] ?? 'debit';
  String get cardHolder => parsedData['holder'] ?? '';
  String get cardNumber => parsedData['number'] ?? '';
  String get cardExpiry => parsedData['expiry'] ?? '';
  String get cardCvv => parsedData['cvv'] ?? '';
  List<int> get cutoffDays {
    final days = parsedData['cutoff_days'];
    if (days == null) return [];
    if (days is List) return List<int>.from(days);
    return [];
  }

  int get installments => parsedData['installments'] ?? 1;
  double get totalDebt {
    final debt = parsedData['total_debt'];
    if (debt == null) return 0.0;
    return (debt as num).toDouble();
  }
}
