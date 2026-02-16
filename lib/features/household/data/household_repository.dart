import 'package:dio/dio.dart';
import 'package:finanzapp_v2/core/network/dio_client.dart';
import 'package:finanzapp_v2/features/household/domain/household.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final householdRepositoryProvider = Provider<HouseholdRepository>((ref) {
  return HouseholdRepository(ref.watch(dioProvider));
});

class HouseholdRepository {
  final Dio _dio;

  HouseholdRepository(this._dio);

  Future<Household?> getMyHousehold() async {
    try {
      final response = await _dio.get('/households/me');
      return Household.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      throw Exception('Failed to fetch household: $e');
    }
  }

  Future<void> requestHousehold(String email) async {
    try {
      await _dio.post('/households/request', data: {'email': email});
    } catch (e) {
      throw Exception('Failed to request household: $e');
    }
  }

  Future<void> acceptHousehold(String householdId) async {
    try {
      await _dio.post('/households/$householdId/accept');
    } catch (e) {
      throw Exception('Failed to accept household: $e');
    }
  }

  Future<void> removeMember(String householdId, String memberId) async {
    try {
      await _dio.delete('/households/$householdId/members/$memberId');
    } catch (e) {
      throw Exception('Failed to remove member: $e');
    }
  }
}
