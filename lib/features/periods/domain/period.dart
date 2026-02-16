class Period {
  final String id;
  final String householdId;
  final int year;
  final int month;
  final DateTime startDate;
  final DateTime endDate;
  final String status; // open, settled, locked

  Period({
    required this.id,
    required this.householdId,
    required this.year,
    required this.month,
    required this.startDate,
    required this.endDate,
    required this.status,
  });

  factory Period.fromJson(Map<String, dynamic> json) {
    return Period(
      id: json['id'],
      householdId: json['household_id'],
      year: json['year'],
      month: json['month'],
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      status: json['status'],
    );
  }
}
