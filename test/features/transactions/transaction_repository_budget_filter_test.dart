import 'package:finanzapp_v2/features/transactions/data/transaction_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_dio_adapter.dart';

void main() {
  group('TransactionRepository.getTransactions budget filter', () {
    test('sends budget_id as a query parameter when given', () async {
      final adapter = FakeDioAdapter(statusCode: 200, responseList: []);
      final repo = TransactionRepository(buildFakeDio(adapter));

      await repo.getTransactions(budgetId: 'goal-42');

      final req = adapter.lastRequest;
      expect(req.method, 'GET');
      expect(req.path, '/transactions');
      expect(req.uri.queryParameters['budget_id'], 'goal-42');
    });

    test('omits budget_id when not given', () async {
      final adapter = FakeDioAdapter(statusCode: 200, responseList: []);
      final repo = TransactionRepository(buildFakeDio(adapter));

      await repo.getTransactions();

      final req = adapter.lastRequest;
      expect(req.uri.queryParameters.containsKey('budget_id'), isFalse);
    });
  });
}
