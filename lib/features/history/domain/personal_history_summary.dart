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

class YearlySummary {
  final double totalIncome;
  final double totalExpense;
  final double balance;
  final double personalIncome;
  final double personalExpense;
  final double householdIncome;
  final double householdExpense;

  YearlySummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    required this.personalIncome,
    required this.personalExpense,
    required this.householdIncome,
    required this.householdExpense,
  });

  factory YearlySummary.fromJson(Map<String, dynamic> json) {
    return YearlySummary(
      totalIncome: (json['total_income'] as num).toDouble(),
      totalExpense: (json['total_expense'] as num).toDouble(),
      balance: (json['balance'] as num).toDouble(),
      personalIncome: (json['personal_income'] as num).toDouble(),
      personalExpense: (json['personal_expense'] as num).toDouble(),
      householdIncome: (json['household_income'] as num?)?.toDouble() ?? 0,
      householdExpense: (json['household_expense'] as num?)?.toDouble() ?? 0,
    );
  }
}
