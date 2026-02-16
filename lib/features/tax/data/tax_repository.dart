import 'package:dio/dio.dart';
import 'package:finanzapp_v2/core/network/dio_client.dart';
import 'package:finanzapp_v2/features/tax/domain/tax_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final taxRepositoryProvider = Provider<TaxRepository>((ref) {
  return TaxRepository(ref.watch(dioProvider));
});

final taxStatusProvider = FutureProvider.family<TaxStatus, int>((
  ref,
  year,
) async {
  return ref.watch(taxRepositoryProvider).getTaxStatus(year);
});

class TaxRepository {
  final Dio _dio;

  TaxRepository(this._dio);

  Future<TaxStatus> getTaxStatus(int year) async {
    try {
      final response = await _dio.get(
        '/tax/status',
        queryParameters: {'year': year},
      );
      return TaxStatus.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to fetch tax status: $e');
    }
  }
}
