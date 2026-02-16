class RecurringPayment {
  final String id;
  final String category;
  final String description;
  final double amount;
  final String frequency;
  final DateTime nextExecutionDate;
  final bool isAutoConfirm;
  final bool isActive;

  RecurringPayment({
    required this.id,
    required this.category,
    required this.description,
    required this.amount,
    required this.frequency,
    required this.nextExecutionDate,
    required this.isAutoConfirm,
    required this.isActive,
  });

  factory RecurringPayment.fromJson(Map<String, dynamic> json) {
    return RecurringPayment(
      id: json['id'],
      category: json['category'],
      description: json['description'] ?? '',
      amount: (json['amount'] as num).toDouble(),
      frequency: json['frequency'],
      nextExecutionDate: DateTime.parse(json['next_date']),
      isAutoConfirm: json['is_auto_confirm'],
      isActive: json['is_active'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'description': description,
      'amount': amount,
      'frequency': frequency,
      'start_date': DateTime.now().toIso8601String(), // basic default for now
      'is_auto_confirm': isAutoConfirm,
      'account_id':
          '00000000-0000-0000-0000-000000000000', // Placeholder, needs UI selection
    };
  }
}
