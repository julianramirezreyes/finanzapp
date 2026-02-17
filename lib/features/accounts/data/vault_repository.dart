import 'package:dio/dio.dart';
import 'package:finanzapp_v2/core/network/dio_client.dart';
import 'package:finanzapp_v2/features/accounts/domain/vault_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final vaultRepositoryProvider = Provider<VaultRepository>((ref) {
  return VaultRepository(ref.watch(dioProvider));
});

final vaultItemsProvider = FutureProvider.family<List<VaultItem>, String>((
  ref,
  accountId,
) async {
  return ref.watch(vaultRepositoryProvider).getVaultItems(accountId);
});

class VaultRepository {
  final Dio _dio;

  VaultRepository(this._dio);

  Future<List<VaultItem>> getVaultItems(String accountId) async {
    try {
      final response = await _dio.get('/accounts/$accountId/vault');
      return (response.data as List).map((e) => VaultItem.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to fetch vault items: $e');
    }
  }

  Future<void> createVaultItem(
    String accountId,
    String title,
    String data,
    bool isCard,
  ) async {
    try {
      await _dio.post(
        '/accounts/$accountId/vault',
        data: {'title': title, 'data': data, 'is_card': isCard},
      );
    } catch (e) {
      throw Exception('Failed to create vault item: $e');
    }
  }

  Future<void> deleteVaultItem(String accountId, String itemId) async {
    try {
      await _dio.delete('/accounts/$accountId/vault/$itemId');
    } catch (e) {
      throw Exception('Failed to delete vault item: $e');
    }
  }
}
