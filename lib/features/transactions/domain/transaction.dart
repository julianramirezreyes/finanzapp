class Transaction {
  final String id;
  final String accountId;
  final double amount;
  final String type; // income, expense, transfer
  final String category;
  final String description;
  final DateTime date;
  final String context; // personal, household

  final String? householdId;
  final String? budgetId;
  final String? destinationAccountId;
  final String userId;
  final bool excludeFromBalance;
  final bool paidWithCreditCard;

  Transaction({
    required this.id,
    required this.accountId,
    required this.amount,
    required this.type,
    required this.category,
    required this.description,
    required this.date,
    required this.context,
    this.householdId,
    this.budgetId,
    this.destinationAccountId,
    required this.userId,
    this.excludeFromBalance = false,
    this.paidWithCreditCard = false,
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
      householdId: json['household_id'],
      budgetId: json['budget_id'],
      destinationAccountId: json['destination_account_id'],
      userId:
          json['user_id'] ??
          '', // Handle potential missing user_id if logic allows, usually required
      excludeFromBalance: json['exclude_from_balance'] ?? false,
      paidWithCreditCard: json['paid_with_credit_card'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'account_id': accountId,
      'amount': amount,
      'type': type,
      'category': category,
      'description': description,
      'date': date.toIso8601String(),
      'context': context,
      'household_id': householdId,
      'budget_id': budgetId,
      'destination_account_id': destinationAccountId,
      'user_id': userId,
      'exclude_from_balance': excludeFromBalance,
      'paid_with_credit_card': paidWithCreditCard,
    };
  }

  Transaction copyWith({
    String? id,
    String? accountId,
    double? amount,
    String? type,
    String? category,
    String? description,
    DateTime? date,
    String? context,
    String? householdId,
    String? budgetId,
    String? destinationAccountId,
    String? userId,
    bool? excludeFromBalance,
    bool? paidWithCreditCard,
  }) {
    return Transaction(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      description: description ?? this.description,
      date: date ?? this.date,
      context: context ?? this.context,
      householdId: householdId ?? this.householdId,
      budgetId: budgetId ?? this.budgetId,
      destinationAccountId: destinationAccountId ?? this.destinationAccountId,
      userId: userId ?? this.userId,
      excludeFromBalance: excludeFromBalance ?? this.excludeFromBalance,
      paidWithCreditCard: paidWithCreditCard ?? this.paidWithCreditCard,
    );
  }
}
