class TaxCategoryProgress {
  final String category;
  final double currentValue;
  final double thresholdValue;
  final double percentage;
  final bool isExceeded;
  final double thresholdUvt;

  TaxCategoryProgress({
    required this.category,
    required this.currentValue,
    required this.thresholdValue,
    required this.percentage,
    required this.isExceeded,
    required this.thresholdUvt,
  });

  factory TaxCategoryProgress.fromJson(Map<String, dynamic> json) {
    return TaxCategoryProgress(
      category: json['category'],
      currentValue: (json['current_value'] as num).toDouble(),
      thresholdValue: (json['threshold_value'] as num).toDouble(),
      percentage: (json['percentage'] as num).toDouble(),
      isExceeded: json['is_exceeded'],
      thresholdUvt: (json['threshold_uvt'] as num).toDouble(),
    );
  }
}

class TaxStatus {
  final int year;
  final double uvtValue;
  final List<TaxCategoryProgress> categories;
  final bool shouldDeclare;

  TaxStatus({
    required this.year,
    required this.uvtValue,
    required this.categories,
    required this.shouldDeclare,
  });

  factory TaxStatus.fromJson(Map<String, dynamic> json) {
    return TaxStatus(
      year: json['year'],
      uvtValue: (json['uvt_value'] as num).toDouble(),
      categories: (json['categories'] as List)
          .map((e) => TaxCategoryProgress.fromJson(e))
          .toList(),
      shouldDeclare: json['should_declare'],
    );
  }
}
