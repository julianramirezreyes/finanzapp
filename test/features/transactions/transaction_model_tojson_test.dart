import 'package:finanzapp_v2/features/transactions/domain/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

Transaction _creditCardTransaction({
  String? vaultCardId = 'vault-card-7',
  int? installments = 3,
  String? creditCardAccountId = 'cc-acct-2',
}) {
  return Transaction(
    id: 'tx-1',
    accountId: 'acc-1',
    amount: 99000,
    type: 'expense',
    category: 'shopping',
    description: 'tv',
    date: DateTime.utc(2026, 3, 10),
    context: 'personal',
    userId: 'user-1',
    paidWithCreditCard: true,
    vaultCardId: vaultCardId,
    installments: installments,
    creditCardAccountId: creditCardAccountId,
  );
}

void main() {
  group('Transaction.toJson() credit-card fields', () {
    test(
      'Scenario 3a.4: toJson includes vault_card_id, installments, credit_card_account_id',
      () {
        final m = _creditCardTransaction().toJson();

        expect(m['vault_card_id'], 'vault-card-7');
        expect(m['installments'], 3);
        expect(m['credit_card_account_id'], 'cc-acct-2');
      },
    );

    test(
      'Scenario 3a.5: fromJson(toJson()) round-trip preserves the three TC fields',
      () {
        final original = _creditCardTransaction();

        final restored = Transaction.fromJson(original.toJson());

        expect(restored.vaultCardId, 'vault-card-7');
        expect(restored.installments, 3);
        expect(restored.creditCardAccountId, 'cc-acct-2');
      },
    );

    test(
      'Scenario 3a.5 (variant): null installments serializes as 1',
      () {
        final m = _creditCardTransaction(installments: null).toJson();

        expect(
          m['installments'],
          1,
          reason: 'installments column is INT DEFAULT 1; never send null',
        );
      },
    );

    test('date is still serialized with the Z offset', () {
      final m = _creditCardTransaction().toJson();
      expect((m['date'] as String).endsWith('Z'), isTrue);
    });
  });
}
