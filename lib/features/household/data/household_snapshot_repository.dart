import 'package:dio/dio.dart';
import 'package:finanzapp_v2/core/network/dio_client.dart';
import 'package:finanzapp_v2/features/household/domain/household_snapshot.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final householdSnapshotRepositoryProvider =
    Provider<HouseholdSnapshotRepository>((ref) {
      return HouseholdSnapshotRepository(ref.watch(dioProvider));
    });

class HouseholdSnapshotRepository {
  final Dio _dio;

  HouseholdSnapshotRepository(this._dio);

  Future<String> syncSnapshot(String householdId, int year, int month) async {
    try {
      final response = await _dio.post(
        '/households/$householdId/sync',
        data: {'year': year, 'month': month},
      );
      return response.data['id'];
    } catch (e) {
      throw Exception('Failed to sync snapshot: $e');
    }
  }

  Future<Map<String, dynamic>> getSnapshot(
    String householdId,
    int year,
    int month,
  ) async {
    try {
      final response = await _dio.get(
        '/households/$householdId/snapshot',
        queryParameters: {'year': year, 'month': month},
      );

      final data = response.data;
      return {
        'snapshot': HouseholdSnapshot.fromJson(data['snapshot']),
        'items': (data['items'] as List)
            .map((e) => HouseholdItem.fromJson(e))
            .toList(),
      };
    } catch (e) {
      throw Exception('Failed to fetch snapshot: $e');
    }
  }

  Future<void> updateItem(
    String itemId,
    double amount,
    String description,
    bool isExcluded,
  ) async {
    try {
      await _dio.put(
        '/household-items/$itemId',
        data: {
          'amount': amount,
          'description': description,
          'is_excluded': isExcluded,
        },
      );
    } catch (e) {
      throw Exception('Failed to update item: $e');
    }
  }

  Future<void> deleteItem(String itemId) async {
    try {
      await _dio.delete('/household-items/$itemId');
    } catch (e) {
      throw Exception('Failed to delete item: $e');
    }
  }
}
