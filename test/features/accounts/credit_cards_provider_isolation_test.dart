import 'package:dio/dio.dart';
import 'package:finanzapp_v2/features/accounts/data/accounts_provider.dart';
import 'package:finanzapp_v2/features/accounts/data/vault_repository.dart';
import 'package:finanzapp_v2/features/accounts/domain/account.dart';
import 'package:finanzapp_v2/features/accounts/domain/vault_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// One account ("bad") throws on every vault call (simulating a transient 401);
/// the other ("good") holds a real credit card. The providers must return the
/// good card instead of letting the bad account empty the whole list.
class _FakeVaultRepo extends VaultRepository {
  _FakeVaultRepo() : super(Dio());

  @override
  Future<List<VaultItem>> getVaultItems(String accountId) async {
    if (accountId == 'bad') throw Exception('simulated 401');
    if (accountId == 'good') {
      return [
        VaultItem(
          id: 'card-1',
          accountId: 'good',
          title: 'Visa',
          data: '{"card_type":"credit"}',
          isCard: true,
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      ];
    }
    return [];
  }

  @override
  Future<List<Map<String, dynamic>>> getVaultDebtSummary(
    String accountId,
  ) async {
    if (accountId == 'bad') throw Exception('simulated 401');
    return [
      {'vault_card_id': 'card-1', 'total_debt': 100.0, 'month_debt': 10.0},
    ];
  }
}

Account _account(String id) =>
    Account(id: id, name: id, type: 'cash', balance: 0, currency: 'COP');

void main() {
  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [
        accountsListProvider.overrideWith(
          (ref) async => [_account('bad'), _account('good')],
        ),
        vaultRepositoryProvider.overrideWithValue(_FakeVaultRepo()),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test(
    'creditCardsWithDebtProvider: one failing account does not empty the list',
    () async {
      final cards = await makeContainer().read(
        creditCardsWithDebtProvider.future,
      );
      expect(
        cards,
        hasLength(1),
        reason: "the good account's card survives the bad account failing",
      );
      expect(cards.single['id'], 'card-1');
      expect(cards.single['total_debt'], 100.0);
    },
  );

  test(
    'allCreditCardsProvider: one failing account does not empty the list',
    () async {
      final cards = await makeContainer().read(allCreditCardsProvider.future);
      expect(cards, hasLength(1));
      expect(cards.single.id, 'card-1');
    },
  );
}
