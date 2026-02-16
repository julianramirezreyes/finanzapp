import 'package:dio/dio.dart';
import 'package:finanzapp_v2/core/network/dio_client.dart';
import 'package:finanzapp_v2/features/budgets/domain/budget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepository(ref.watch(dioProvider));
});

class BudgetRepository {
  final Dio _dio;

  BudgetRepository(this._dio);

  Future<List<Budget>> getBudgets({String? householdId}) async {
    try {
      final response = await _dio.get(
        '/budgets',
        queryParameters: householdId != null
            ? {'household_id': householdId}
            : null,
      );
      return (response.data as List).map((e) => Budget.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to fetch budgets: $e');
    }
  }

  Future<void> createBudget({
    required String category,
    required double amount,
    required String period,
    String type = 'expense',
    double? targetAmount,
    DateTime? targetDate,
    String? icon,
    String? color,
    int months = 1,
    bool isRecurrent = false,
    String? householdId,
  }) async {
    try {
      await _dio.post(
        '/budgets',
        data: {
          'category': category,
          'amount': amount,
          'period': period,
          'type': type,
          'target_amount': targetAmount,
          'target_date': targetDate?.toIso8601String().split('T')[0],
          'icon': icon,
          'color': color,
          'months': months,
          'is_recurrent': isRecurrent,
          'household_id': householdId,
        },
      );
    } catch (e) {
      throw Exception('Failed to create budget: $e');
    }
  }

  Future<void> deleteBudget(String id) async {
    try {
      await _dio.delete('/budgets/$id');
    } catch (e) {
      throw Exception('Failed to delete budget: $e');
    }
  }

  Future<void> updateBudget(Budget budget, {String? householdId}) async {
    try {
      await _dio.put(
        '/budgets/${budget.id}',
        data: {
          'category': budget.category,
          'amount': budget.limitAmount,
          'period': budget.period,
          'type': budget.type,
          'target_amount': budget.targetAmount,
          'target_date': budget.targetDate?.toIso8601String().split('T')[0],
          'icon': budget.icon,
          'color': budget.color,
          'months': budget.months,
          'is_recurrent': budget.isRecurrent,
          'household_id': householdId,
        },
      );
    } catch (e) {
      throw Exception('Failed to update budget: $e');
    }
  }

  Future<void> reorderBudgets(List<Budget> budgets) async {
    try {
      final items = budgets
          .asMap()
          .entries
          .map((e) => {'id': e.value.id, 'order_index': e.key})
          .toList();

      await _dio.post('/budgets/reorder', data: items);
    } catch (e) {
      throw Exception('Failed to reorder budgets: $e');
    }
  }
}
