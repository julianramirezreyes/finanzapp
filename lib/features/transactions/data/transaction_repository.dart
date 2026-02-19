import 'package:dio/dio.dart';
import 'package:finanzapp_v2/core/network/dio_client.dart';
import 'package:finanzapp_v2/features/transactions/domain/transaction.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository(ref.watch(dioProvider));
});

class TransactionRepository {
  final Dio _dio;

  TransactionRepository(this._dio);

  // Personal Transactions
  Future<List<Transaction>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async {
    try {
      final queryParams = <String, dynamic>{'limit': limit};
      if (startDate != null) {
        queryParams['start_date'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['end_date'] = endDate.toIso8601String();
      }

      final response = await _dio.get(
        '/transactions',
        queryParameters: queryParams,
      );
      final List data = response.data;
      return data.map((json) => Transaction.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch transactions: $e');
    }
  }

  // Household Transactions
  Future<List<Transaction>> getHouseholdTransactions(String householdId) async {
    try {
      final response = await _dio.get('/households/$householdId/transactions');
      final List data = response.data;
      return data.map((json) => Transaction.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch household transactions: $e');
    }
  }

  Future<void> createTransaction({
    required String accountId,
    required double amount,
    required String type,
    required String category,
    required String description,
    required DateTime date,
    required String context,
    String? householdId,
    String? budgetId,
    String? destinationAccountId,
    bool excludeFromBalance = false,
    bool paidWithCreditCard = false,
  }) async {
    try {
      final payload = {
        'account_id': accountId,
        'amount': amount,
        'type': type,
        'category': category,
        'description': description,
        'date': date.toUtc().toIso8601String(),
        'context': context,
        'exclude_from_balance': excludeFromBalance,
        'paid_with_credit_card': paidWithCreditCard,
      };

      if (householdId != null) {
        payload['household_id'] = householdId;
      }

      if (budgetId != null) {
        payload['budget_id'] = budgetId;
      }

      if (destinationAccountId != null) {
        payload['destination_account_id'] = destinationAccountId;
      }

      await _dio.post('/transactions', data: payload);
    } catch (e) {
      throw Exception('Failed to create transaction: $e');
    }
  }

  Future<void> updateTransaction(Transaction transaction) async {
    try {
      // Assuming API accepts partial or full updates. Sending full body is safer given current backend.
      // We need to map camelCase fields back to snake_case for API if toJson() doesn't do it perfectly matches backend expectations.
      // Our toJson() maps to snake_case, so it should be fine.
      await _dio.put(
        '/transactions/${transaction.id}',
        data: transaction.toJson(),
      );
    } catch (e) {
      throw Exception('Error updating transaction: $e');
    }
  }

  Future<void> deleteTransaction(String id) async {
    try {
      await _dio.delete('/transactions/$id');
    } catch (e) {
      throw Exception('Error deleting transaction: $e');
    }
  }
}
