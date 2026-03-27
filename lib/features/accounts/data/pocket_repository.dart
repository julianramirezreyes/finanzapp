import 'package:dio/dio.dart';
import 'package:finanzapp_v2/core/network/dio_client.dart';
import 'package:finanzapp_v2/features/accounts/domain/pocket.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final pocketRepositoryProvider = Provider<PocketRepository>((ref) {
  return PocketRepository(ref.watch(dioProvider));
});

class PocketRepository {
  final Dio _dio;

  PocketRepository(this._dio);

  Future<List<Pocket>> getPockets(String accountId) async {
    try {
      final response = await _dio.get('/accounts/$accountId/pockets');
      final List data = response.data;
      return data.map((json) => Pocket.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch pockets: $e');
    }
  }

  Future<Pocket> createPocket(
    String accountId,
    String name,
    double initialBalance,
  ) async {
    try {
      final response = await _dio.post(
        '/accounts/$accountId/pockets',
        data: {'name': name, 'initial_balance': initialBalance},
      );
      return Pocket.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create pocket: $e');
    }
  }

  Future<Pocket> deposit(
    String accountId,
    String pocketId,
    double amount,
  ) async {
    try {
      final response = await _dio.post(
        '/accounts/$accountId/pockets/$pocketId/deposit',
        data: {'amount': amount},
      );
      return Pocket.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to deposit: $e');
    }
  }

  Future<Pocket> withdraw(
    String accountId,
    String pocketId,
    double amount,
  ) async {
    try {
      final response = await _dio.post(
        '/accounts/$accountId/pockets/$pocketId/withdraw',
        data: {'amount': amount},
      );
      return Pocket.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to withdraw: $e');
    }
  }

  Future<void> deletePocket(String accountId, String pocketId) async {
    try {
      await _dio.delete('/accounts/$accountId/pockets/$pocketId');
    } catch (e) {
      throw Exception('Failed to delete pocket: $e');
    }
  }

  Future<Pocket> updatePocket(
    String accountId,
    String pocketId,
    String name,
  ) async {
    try {
      final response = await _dio.put(
        '/accounts/$accountId/pockets/$pocketId',
        data: {'name': name},
      );
      return Pocket.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update pocket: $e');
    }
  }
}

// Provider para obtener bolsillos de una cuenta
final pocketsProvider = FutureProvider.family<List<Pocket>, String>((
  ref,
  accountId,
) async {
  final repository = ref.watch(pocketRepositoryProvider);
  return repository.getPockets(accountId);
});
