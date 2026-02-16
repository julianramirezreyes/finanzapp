class Account {
  final String id;
  final String name;
  final String type;
  final double balance;
  final String currency;
  final bool includeInNetWorth;

  Account({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    required this.currency,
    this.includeInNetWorth = true,
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      balance: (json['balance'] as num).toDouble(),
      currency: json['currency'],
      includeInNetWorth: json['include_in_net_worth'] ?? true,
    );
  }
}
