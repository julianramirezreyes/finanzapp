import 'account.dart';

class Pocket {
  final String id;
  final String accountId;
  final String name;
  final double balance;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Pocket({
    required this.id,
    required this.accountId,
    required this.name,
    required this.balance,
    this.createdAt,
    this.updatedAt,
  });

  factory Pocket.fromJson(Map<String, dynamic> json) {
    return Pocket(
      id: json['id'],
      accountId: json['account_id'],
      name: json['name'],
      balance: (json['balance'] as num).toDouble(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'account_id': accountId,
      'name': name,
      'balance': balance,
    };
  }

  Pocket copyWith({
    String? id,
    String? accountId,
    String? name,
    double? balance,
  }) {
    return Pocket(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class AccountWithPockets {
  final Account account;
  final List<Pocket> pockets;
  final double totalValue;

  AccountWithPockets({
    required this.account,
    required this.pockets,
    required this.totalValue,
  });

  factory AccountWithPockets.fromJson(Map<String, dynamic> json) {
    return AccountWithPockets(
      account: Account.fromJson(json),
      pockets:
          (json['pockets'] as List<dynamic>?)
              ?.map((p) => Pocket.fromJson(p))
              .toList() ??
          [],
      totalValue: (json['total_value'] as num?)?.toDouble() ?? 0,
    );
  }
}
