import 'package:dio/dio.dart';
import 'package:finanzapp_v2/core/network/dio_client.dart';
import 'package:finanzapp_v2/features/automation/domain/recurring_payment.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final automationRepositoryProvider = Provider<AutomationRepository>((ref) {
  return AutomationRepository(ref.watch(dioProvider));
});

final pendingPaymentsProvider = FutureProvider<List<RecurringPayment>>((
  ref,
) async {
  return ref.watch(automationRepositoryProvider).getPendingPayments();
});

class AutomationRepository {
  final Dio _dio;

  AutomationRepository(this._dio);

  Future<List<RecurringPayment>> getPendingPayments() async {
    try {
      final response = await _dio.get('/automation/pending');
      final List<dynamic> list = response.data;
      return list.map((e) => RecurringPayment.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to fetch pending payments: $e');
    }
  }

  Future<void> executePayment(String id) async {
    try {
      await _dio.post('/automation/execute/$id');
    } catch (e) {
      throw Exception('Failed to execute payment: $e');
    }
  }

  Future<RecurringPayment> createPayment(RecurringPayment payment) async {
    try {
      final response = await _dio.post(
        '/automation/payments',
        data: payment.toJson(),
      );
      return RecurringPayment.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create payment: $e');
    }
  }
}
