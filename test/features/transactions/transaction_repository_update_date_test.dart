import 'package:finanzapp_v2/features/transactions/data/transaction_repository.dart';
import 'package:finanzapp_v2/features/transactions/domain/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_dio_adapter.dart';

/// Builds a Transaction whose [date] is a LOCAL DateTime (no `.utc`),
/// so the test proves `toJson()` itself applies `.toUtc()` before serializing.
Transaction _localDatedTransaction({String id = 'tx-1'}) {
  return Transaction(
    id: id,
    accountId: 'acc-1',
    amount: 1000,
    type: 'expense',
    category: 'food',
    description: 'lunch',
    // LOCAL (naive) date on purpose — without .toUtc() this serializes
    // without the 'Z' offset and the Go backend rejects it with 400.
    date: DateTime(2026, 1, 15, 10, 30),
    context: 'personal',
    userId: 'user-1',
  );
}

void main() {
  group('TransactionRepository.updateTransaction (date UTC offset)', () {
    test(
      'Scenario 3a.1: editing a transaction serializes date with Z offset',
      () async {
        final adapter = FakeDioAdapter(statusCode: 200, responseJson: {});
        final repo = TransactionRepository(buildFakeDio(adapter));

        await repo.updateTransaction(_localDatedTransaction(id: 'tx-42'));

        expect(adapter.requests, hasLength(1));
        final req = adapter.lastRequest;
        expect(req.method, 'PUT');
        expect(req.path, '/transactions/tx-42');

        final body = req.json;
        expect(
          (body['date'] as String).endsWith('Z'),
          isTrue,
          reason: 'date must be serialized as UTC with the Z offset',
        );
      },
    );

    test(
      'Scenario 3a.6 (regression): creating a transaction keeps date with Z',
      () async {
        final adapter = FakeDioAdapter(statusCode: 201, responseJson: {});
        final repo = TransactionRepository(buildFakeDio(adapter));

        await repo.createTransaction(
          accountId: 'acc-1',
          amount: 1000,
          type: 'expense',
          category: 'food',
          description: 'lunch',
          date: DateTime(2026, 1, 15, 10, 30),
          context: 'personal',
        );

        expect(adapter.requests, hasLength(1));
        final body = adapter.lastRequest.json;
        expect((body['date'] as String).endsWith('Z'), isTrue);
      },
    );
  });
}
