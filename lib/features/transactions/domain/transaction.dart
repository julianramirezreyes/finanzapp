class Transaction {
  final String id;
  final String accountId;
  final double amount;
  final String type; // income, expense, transfer
  final String category;
  final String description;
  final DateTime date;
  final String context; // personal, household

  Transaction({
    required this.id,
    required this.accountId,
    required this.amount,
    required this.type,
    required this.category,
    required this.description,
    required this.date,
    required this.context,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      accountId: json['account_id'],
      amount: (json['amount'] as num).toDouble(),
      type: json['type'],
      category: json['category'],
      description: json['description'] ?? '',
      date: DateTime.parse(json['date']),
      context: json['context'],
    );
  }
}
