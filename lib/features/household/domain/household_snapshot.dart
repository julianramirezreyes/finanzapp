class HouseholdSnapshot {
  final String id;
  final String householdId;
  final int year;
  final int month;
  final String status;
  final double totalIncomeA;
  final double totalIncomeB;
  final double totalExpenses;
  final double balance;

  HouseholdSnapshot({
    required this.id,
    required this.householdId,
    required this.year,
    required this.month,
    required this.status,
    required this.totalIncomeA,
    required this.totalIncomeB,
    required this.totalExpenses,
    required this.balance,
  });

  factory HouseholdSnapshot.fromJson(Map<String, dynamic> json) {
    return HouseholdSnapshot(
      id: json['id'],
      householdId: json['household_id'],
      year: json['year'],
      month: json['month'],
      status: json['status'],
      totalIncomeA: (json['total_income_a'] as num).toDouble(),
      totalIncomeB: (json['total_income_b'] as num).toDouble(),
      totalExpenses: (json['total_expenses'] as num).toDouble(),
      balance: (json['balance'] as num).toDouble(),
    );
  }
}

class HouseholdItem {
  final String id;
  final String snapshotId;
  final String? originalTransactionId;
  final String? userId; // Owner of the item in snapshot context
  final double amount;
  final String type;
  final String? description;
  final String? category;
  final DateTime date;
  final bool isExcluded;

  HouseholdItem({
    required this.id,
    required this.snapshotId,
    this.originalTransactionId,
    this.userId,
    required this.amount,
    required this.type,
    this.description,
    this.category,
    required this.date,
    required this.isExcluded,
  });

  factory HouseholdItem.fromJson(Map<String, dynamic> json) {
    return HouseholdItem(
      id: json['id'],
      snapshotId: json['snapshot_id'],
      originalTransactionId: json['original_transaction_id'],
      userId: json['user_id'],
      amount: (json['amount'] as num).toDouble(),
      type: json['type'],
      description: json['description'],
      category: json['category'],
      date: DateTime.parse(json['date']),
      isExcluded: json['is_excluded'],
    );
  }
}
