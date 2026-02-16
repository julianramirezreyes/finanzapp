class Settlement {
  final double totalAmount;
  final double shareA;
  final double shareB;
  final double paidByA;
  final double paidByB;
  final double diffA;
  final double diffB;
  final String debtorId;
  final String creditorId;
  final double balance;

  Settlement({
    required this.totalAmount,
    required this.shareA,
    required this.shareB,
    required this.paidByA,
    required this.paidByB,
    required this.diffA,
    required this.diffB,
    required this.debtorId,
    required this.creditorId,
    required this.balance,
  });

  factory Settlement.fromJson(Map<String, dynamic> json) {
    return Settlement(
      totalAmount: (json['total_amount'] as num).toDouble(),
      shareA: (json['share_a'] as num).toDouble(),
      shareB: (json['share_b'] as num).toDouble(),
      paidByA: (json['paid_by_a'] as num).toDouble(),
      paidByB: (json['paid_by_b'] as num).toDouble(),
      diffA: (json['diff_a'] as num).toDouble(),
      diffB: (json['diff_b'] as num).toDouble(),
      debtorId: json['debtor_id'] ?? '',
      creditorId: json['creditor_id'] ?? '',
      balance: (json['balance'] as num).toDouble(),
    );
  }
}
