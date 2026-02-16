class Household {
  final String id;
  final String userAId;
  final String? userBId;
  final String userAEmail;
  final String? userBEmail;
  final String status;
  final DateTime createdAt;

  Household({
    required this.id,
    required this.userAId,
    this.userBId,
    required this.userAEmail,
    this.userBEmail,
    required this.status,
    required this.createdAt,
  });

  factory Household.fromJson(Map<String, dynamic> json) {
    return Household(
      id: json['id'],
      userAId: json['user_a_id'],
      userBId: json['user_b_id'],
      userAEmail: json['user_a_email'] ?? '',
      userBEmail: json['user_b_email'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
