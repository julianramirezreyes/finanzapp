import 'package:dio/dio.dart';
import 'package:finanzapp_v2/core/network/dio_client.dart';
import 'package:finanzapp_v2/features/periods/domain/period.dart';
import 'package:finanzapp_v2/features/periods/domain/settlement.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final periodRepositoryProvider = Provider<PeriodRepository>((ref) {
  return PeriodRepository(ref.watch(dioProvider));
});

class PeriodRepository {
  final Dio _dio;

  PeriodRepository(this._dio);

  Future<List<Period>> getPeriods(String householdId) async {
    try {
      final response = await _dio.get('/households/$householdId/periods');
      final List data = response.data;
      return data.map((json) => Period.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch periods: $e');
    }
  }

  Future<void> createPeriod(String householdId, int year, int month) async {
    try {
      await _dio.post(
        '/households/$householdId/periods',
        data: {'year': year, 'month': month},
      );
    } catch (e) {
      throw Exception('Failed to create period: $e');
    }
  }

  // Fetch settlement preview (dry-run or actual if settled)
  Future<Settlement> getSettlement(String householdId, String periodId) async {
    try {
      final response = await _dio.get(
        '/households/$householdId/periods/$periodId/settlement',
      );
      return Settlement.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to fetch settlement: $e');
    }
  }

  // Execute settlement (lock period)
  Future<void> executeSettlement(String householdId, String periodId) async {
    try {
      await _dio.post('/households/$householdId/periods/$periodId/settle');
    } catch (e) {
      throw Exception('Failed to execute settlement: $e');
    }
  }
}
