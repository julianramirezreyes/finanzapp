import 'package:dio/dio.dart';
import 'package:finanzapp_v2/core/network/dio_client.dart';
import 'package:finanzapp_v2/features/budgets/domain/budget_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final budgetConfigRepositoryProvider = Provider<BudgetConfigRepository>((ref) {
  return BudgetConfigRepository(ref.watch(dioProvider));
});

class BudgetConfigRepository {
  final Dio _dio;

  BudgetConfigRepository(this._dio);

  Future<BudgetConfig> getConfig(String type, {String? householdId}) async {
    try {
      final response = await _dio.get(
        '/budget-configs/$type',
        queryParameters: householdId != null
            ? {'household_id': householdId}
            : null,
      );
      return BudgetConfig.fromJson(response.data);
    } catch (e) {
      // If 404, return default empty config (with dummy ID, or handle in provider)
      // Ideally backend returns 404 if not found.
      if (e is DioException && e.response?.statusCode == 404) {
        return BudgetConfig(
          id: '', // Empty ID indicates new
          updatedAt: DateTime.now(),
          householdId: householdId,
        );
      }
      rethrow;
    }
  }

  Future<BudgetConfig> upsertConfig(BudgetConfig config) async {
    final response = await _dio.post('/budget-configs', data: config.toJson());
    return BudgetConfig.fromJson(response.data);
  }
}
