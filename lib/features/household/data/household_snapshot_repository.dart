import 'dart:convert';
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
        options: Options(
          validateStatus: (status) => true, // Handle all statuses manually
        ),
      );

      if (response.statusCode == 404) {
        throw Exception('Snapshot not found (404)');
      }

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to fetch snapshot: Status ${response.statusCode}',
        );
      }

      final data = response.data;

      // FALLBACK: If status was 200 but body is String (likely due to missing Content-Type header),
      // try to parse it as JSON manually.
      if (data is String) {
        if (data.contains('404') || data.contains('Not Found')) {
          throw Exception('Snapshot not found (404-in-body)');
        }

        try {
          final decoded = jsonDecode(data);
          if (decoded is Map<String, dynamic>) {
            return {
              'snapshot': HouseholdSnapshot.fromJson(decoded['snapshot']),
              'items': (decoded['items'] as List)
                  .map((e) => HouseholdItem.fromJson(e))
                  .toList(),
            };
          }
        } catch (e) {
          throw Exception('Failed to parse snapshot JSON: $e');
        }

        throw Exception('Invalid data format: Expected Map, got String: $data');
      }

      if (data is! Map<String, dynamic>) {
        throw Exception(
          'Invalid data format: Expected Map, got ${data.runtimeType}',
        );
      }

      return {
        'snapshot': HouseholdSnapshot.fromJson(data['snapshot']),
        'items': (data['items'] as List)
            .map((e) => HouseholdItem.fromJson(e))
            .toList(),
      };
    } catch (e) {
      // Re-throw if it's already a clean exception, otherwise wrap
      if (e.toString().contains('404')) rethrow;
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
