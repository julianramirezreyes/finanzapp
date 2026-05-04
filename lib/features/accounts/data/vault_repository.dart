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

// Credit cards with debt info for the dropdown
final creditCardsWithDebtProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final accountsAsync = ref.watch(accountsListProvider);
  return accountsAsync.maybeWhen(
    data: (accounts) async {
      final allCardsWithDebt = <Map<String, dynamic>>[];
      for (final account in accounts) {
        // Get both vault items and debt summary
        final vaultRepo = ref.watch(vaultRepositoryProvider);
        final items = await vaultRepo.getVaultItems(account.id);
        final debts = await vaultRepo.getVaultDebtSummary(account.id);

        // Filter credit cards and match with debt
        final creditCards = items.where(
          (item) => item.isCard && item.cardType == 'credit',
        );
        for (final card in creditCards) {
          // Find matching debt (match by vault_card_id)
          final debtInfo = debts.firstWhere(
            (d) => d['vault_card_id'] == card.id,
            orElse: () => <String, dynamic>{
              'total_debt': 0.0,
              'month_debt': 0.0,
            },
          );
          allCardsWithDebt.add({
            'id': card.id,
            'account_id': account.id,
            'title': card.title,
            'total_debt': debtInfo['total_debt'] ?? 0.0,
            'month_debt': debtInfo['month_debt'] ?? 0.0,
          });
        }
      }
      return allCardsWithDebt;
    },
    orElse: () => <Map<String, dynamic>>[],
  );
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

  Future<void> clearDebt({
    required String accountId,
    required String vaultCardId,
  }) async {
    try {
      await _dio.post(
        '/accounts/$accountId/vault/clear-debt',
        data: {'vault_card_id': vaultCardId},
      );
    } catch (e) {
      throw Exception('Failed to clear debt: $e');
    }
  }
}
