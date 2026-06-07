import 'package:finanzapp_v2/features/transactions/data/transaction_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_dio_adapter.dart';

void main() {
  group('TransactionRepository.payCreditCard (new backend contract)', () {
    test(
      'sends vault_card_id (not credit_card_account_id) in the payload',
      () async {
        final adapter = FakeDioAdapter(statusCode: 200, responseJson: {});
        final repo = TransactionRepository(buildFakeDio(adapter));

        await repo.payCreditCard(
          vaultCardId: 'vault-card-123',
          amount: 30000,
          accountId: 'paying-account-9',
          date: DateTime.utc(2026, 1, 15),
          description: 'Pago de prueba',
        );

        expect(adapter.requests, hasLength(1));
        final req = adapter.lastRequest;
        expect(req.method, 'POST');
        expect(req.path, '/transactions/pay-credit');

        final body = req.json;
        // The backend now keys the payment to the card via vault_card_id.
        expect(body['vault_card_id'], 'vault-card-123');
        // The old key must be gone — sending it would be a 400 on the new backend.
        expect(body.containsKey('credit_card_account_id'), isFalse);
        expect(body['account_id'], 'paying-account-9');
        expect(body['amount'], 30000);
        expect(body['description'], 'Pago de prueba');
        expect(body['date'], isNotNull);
      },
    );

    test('defaults the description when none is given', () async {
      final adapter = FakeDioAdapter(statusCode: 200, responseJson: {});
      final repo = TransactionRepository(buildFakeDio(adapter));

      await repo.payCreditCard(
        vaultCardId: 'vault-card-1',
        amount: 10000,
        accountId: 'acc-1',
        date: DateTime.utc(2026, 2, 1),
      );

      expect(
        adapter.lastRequest.json['description'],
        'Pago Tarjeta de Crédito',
      );
    });
  });
}
