class Account {
  final String id;
  final String name;
  final String type;
  final double balance;
  final String currency;
  final bool includeInNetWorth;
  final int displayOrder;
  final int? cutoffDay;

  Account({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    required this.currency,
    this.includeInNetWorth = true,
    this.displayOrder = 0,
    this.cutoffDay,
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      balance: (json['balance'] as num).toDouble(),
      currency: json['currency'],
      includeInNetWorth: json['include_in_net_worth'] ?? true,
      displayOrder: json['display_order'] ?? 0,
      cutoffDay: json['cutoff_day'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'balance': balance,
      'currency': currency,
      'include_in_net_worth': includeInNetWorth,
      'display_order': displayOrder,
      'cutoff_day': cutoffDay,
    };
  }

  Account copyWith({
    String? id,
    String? name,
    String? type,
    double? balance,
    String? currency,
    bool? includeInNetWorth,
    int? displayOrder,
    int? cutoffDay,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      includeInNetWorth: includeInNetWorth ?? this.includeInNetWorth,
      displayOrder: displayOrder ?? this.displayOrder,
      cutoffDay: cutoffDay ?? this.cutoffDay,
    );
  }
}
