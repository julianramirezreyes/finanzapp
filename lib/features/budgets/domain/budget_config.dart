class BudgetConfig {
  final String id;
  final String? householdId;
  final String? userId;
  final double incomeA;
  final double incomeB;
  final double personalIncome;
  final int pctExpense;
  final int pctSavings;
  final int pctInvestment;
  final DateTime updatedAt;

  BudgetConfig({
    required this.id,
    this.householdId,
    this.userId,
    this.incomeA = 0,
    this.incomeB = 0,
    this.personalIncome = 0,
    this.pctExpense = 50,
    this.pctSavings = 30,
    this.pctInvestment = 20,
    required this.updatedAt,
  });

  factory BudgetConfig.fromJson(Map<String, dynamic> json) {
    return BudgetConfig(
      id: json['id'],
      householdId: json['household_id'],
      userId: json['user_id'],
      incomeA: (json['income_a'] as num?)?.toDouble() ?? 0,
      incomeB: (json['income_b'] as num?)?.toDouble() ?? 0,
      personalIncome: (json['personal_income'] as num?)?.toDouble() ?? 0,
      pctExpense: json['pct_expense'] ?? 50,
      pctSavings: json['pct_savings'] ?? 30,
      pctInvestment: json['pct_investment'] ?? 20,
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'household_id': householdId,
      'user_id': userId,
      'income_a': incomeA,
      'income_b': incomeB,
      'personal_income': personalIncome,
      'pct_expense': pctExpense,
      'pct_savings': pctSavings,
      'pct_investment': pctInvestment,
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
    if (id.isNotEmpty) {
      data['id'] = id;
    }
    return data;
  }

  BudgetConfig copyWith({
    double? incomeA,
    double? incomeB,
    double? personalIncome,
    int? pctExpense,
    int? pctSavings,
    int? pctInvestment,
  }) {
    return BudgetConfig(
      id: id,
      householdId: householdId,
      userId: userId,
      incomeA: incomeA ?? this.incomeA,
      incomeB: incomeB ?? this.incomeB,
      personalIncome: personalIncome ?? this.personalIncome,
      pctExpense: pctExpense ?? this.pctExpense,
      pctSavings: pctSavings ?? this.pctSavings,
      pctInvestment: pctInvestment ?? this.pctInvestment,
      updatedAt: DateTime.now(),
    );
  }
}
