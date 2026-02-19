class PersonalHistorySummary {
  final double totalIncome;
  final double totalExpense;
  final double expensePersonal;
  final double expenseHousehold;
  final double movements;
  final double balance;
  final int count;
  final List<dynamic> transactions; // avoiding full circular dep, or map later

  PersonalHistorySummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.expensePersonal,
    required this.expenseHousehold,
    required this.movements,
    required this.balance,
    required this.count,
    required this.transactions,
  });

  factory PersonalHistorySummary.fromJson(Map<String, dynamic> json) {
    return PersonalHistorySummary(
      totalIncome: (json['total_income'] as num).toDouble(),
      totalExpense: (json['total_expense'] as num).toDouble(),
      expensePersonal: (json['expense_personal'] as num).toDouble(),
      expenseHousehold: (json['expense_household'] as num).toDouble(),
      movements: ((json['movements'] as num?) ?? 0).toDouble(),
      balance: (json['balance'] as num).toDouble(),
      count: json['count'] as int,
      transactions: json['transactions'] as List<dynamic>,
    );
  }
}
