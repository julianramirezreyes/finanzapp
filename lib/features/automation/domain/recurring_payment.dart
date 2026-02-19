class RecurringPayment {
  final String id;
  final String accountId;
  final String context; // personal, household
  final String? householdId;
  final String? budgetId;
  final String category;
  final String description;
  final double amount;
  final String frequency;
  final DateTime startDate;
  final DateTime nextExecutionDate;
  final bool isAutoConfirm;
  final bool isActive;

  RecurringPayment({
    required this.id,
    required this.accountId,
    required this.context,
    this.householdId,
    this.budgetId,
    required this.category,
    required this.description,
    required this.amount,
    required this.frequency,
    required this.startDate,
    required this.nextExecutionDate,
    required this.isAutoConfirm,
    required this.isActive,
  });

  factory RecurringPayment.fromJson(Map<String, dynamic> json) {
    return RecurringPayment(
      id: json['id'],
      accountId: json['account_id'],
      context: json['context'] ?? 'personal',
      householdId: json['household_id'],
      budgetId: json['budget_id'],
      category: json['category'],
      description: json['description'] ?? '',
      amount: (json['amount'] as num).toDouble(),
      frequency: json['frequency'],
      startDate: DateTime.parse(json['start_date']),
      nextExecutionDate: DateTime.parse(json['next_date']),
      isAutoConfirm: json['is_auto_confirm'],
      isActive: json['is_active'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'account_id': accountId,
      'context': context,
      'household_id': householdId,
      'budget_id': budgetId,
      'category': category,
      'description': description,
      'amount': amount,
      'frequency': frequency,
      'start_date': startDate.toIso8601String(),
      'next_date': nextExecutionDate.toIso8601String(),
      'is_auto_confirm': isAutoConfirm,
      'is_active': isActive,
    };
  }
}
