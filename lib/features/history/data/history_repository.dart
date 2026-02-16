import 'package:dio/dio.dart';
import 'package:finanzapp_v2/core/network/dio_client.dart';
import 'package:finanzapp_v2/features/history/domain/personal_history_summary.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return HistoryRepository(ref.watch(dioProvider));
});

class HistoryRepository {
  final Dio _dio;

  HistoryRepository(this._dio);

  Future<PersonalHistorySummary> getPersonalHistory({
    int? month,
    int? year,
  }) async {
    try {
      final response = await _dio.get(
        '/history/personal',
        queryParameters: {
          if (month != null) 'month': month,
          if (year != null) 'year': year,
        },
      );
      return PersonalHistorySummary.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to fetch personal history: $e');
    }
  }
}
