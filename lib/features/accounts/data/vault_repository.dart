
import 'package:dio/dio.dart';
import 'package:finanzapp_v2/core/network/dio_client.dart';
import 'package:finanzapp_v2/features/accounts/data/accounts_provider.dart';
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

final creditCardsProvider = FutureProvider.family<List<VaultItem>, String>((
  ref,
  accountId,
) async {
  final items = await ref
      .watch(vaultRepositoryProvider)
      .getVaultItems(accountId);
  return items.where((item) {
    if (!item.isCard) return false;
    return item.cardType == 'credit';
  }).toList();
});

final allCreditCardsProvider = FutureProvider<List<VaultItem>>((ref) async {
  final accountsAsync = ref.watch(accountsListProvider);
  return accountsAsync.maybeWhen(
    data: (accounts) async {
      final allCards = <VaultItem>[];
      for (final account in accounts) {
        final cards = await ref.watch(creditCardsProvider(account.id).future);
        allCards.addAll(cards);
      }
      return allCards;
    },
    orElse: () => <VaultItem>[],
  );
});

final vaultDebtSummaryProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      accountId,
    ) async {
      return ref.watch(vaultRepositoryProvider).getVaultDebtSummary(accountId);
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

  Future<void> updateVaultItem(
    String accountId,
    String itemId,
    String title,
    String data,
    bool isCard,
  ) async {
    try {
      await _dio.put(
        '/accounts/$accountId/vault/$itemId',
        data: {'title': title, 'data': data, 'is_card': isCard},
      );
    } catch (e) {
      throw Exception('Failed to update vault item: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getVaultDebtSummary(
    String accountId,
  ) async {
    try {
      final response = await _dio.get('/accounts/$accountId/vault/debt');
      return (response.data as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch vault debt summary: $e');
    }
  }
}
