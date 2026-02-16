class Budget {
  final String id;
  final String userId;
  final String category;
  final double limitAmount; // renamed from amount to be clear
  final String period;
  final String type; // expense, saving, investment
  final double? targetAmount;
  final double currentAmount;
  final DateTime? targetDate;
  final String? icon;
  final String? color;

  final int months;
  final bool isRecurrent;
  final double monthlyQuota;
  final int orderIndex;

  Budget({
    required this.id,
    required this.userId,
    required this.category,
    required this.limitAmount,
    required this.period,
    this.type = 'expense',
    this.targetAmount,
    this.currentAmount = 0,
    this.targetDate,
    this.icon,
    this.color,
    this.months = 1,
    this.isRecurrent = false,
    this.monthlyQuota = 0,
    this.orderIndex = 0,
  });

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'],
      userId: json['user_id'],
      category: json['category'],
      limitAmount: (json['limit_amount'] ?? json['amount'] as num).toDouble(),
      period: json['period'],
      type: json['type'] ?? 'expense',
      targetAmount: json['target_amount'] != null
          ? (json['target_amount'] as num).toDouble()
          : null,
      currentAmount: (json['current_amount'] as num?)?.toDouble() ?? 0,
      targetDate: json['target_date'] != null
          ? DateTime.tryParse(json['target_date'])
          : null,
      icon: json['icon'],
      color: json['color'],
      months: json['months'] ?? 1,
      isRecurrent: json['is_recurrent'] ?? false,
      monthlyQuota: (json['monthly_quota'] as num?)?.toDouble() ?? 0,
      orderIndex: json['order_index'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'amount': limitAmount,
      'period': period,
      'type': type,
      'target_amount': targetAmount,
      'target_date': targetDate?.toIso8601String().split('T')[0],
      'icon': icon,
      'color': color,
      'months': months,
      'is_recurrent': isRecurrent,
      'order_index': orderIndex,
    };
  }
}
