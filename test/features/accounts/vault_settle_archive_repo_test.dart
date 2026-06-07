import 'package:finanzapp_v2/features/accounts/data/vault_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_dio_adapter.dart';

void main() {
  group('VaultRepository settle/archive endpoints', () {
    test('settleCardDebt POSTs to the settle endpoint and returns the amount', () async {
      final adapter = FakeDioAdapter(
        statusCode: 200,
        responseJson: {'settled_amount': 283530.0},
      );
      final repo = VaultRepository(buildFakeDio(adapter));

      final amount = await repo.settleCardDebt('acc-1', 'card-9');

      expect(adapter.lastRequest.method, 'POST');
      expect(adapter.lastRequest.path, '/accounts/acc-1/vault/card-9/settle');
      expect(amount, 283530.0);
    });

    test('archiveCard POSTs to the archive endpoint', () async {
      final adapter = FakeDioAdapter(statusCode: 200, responseJson: {});
      final repo = VaultRepository(buildFakeDio(adapter));

      await repo.archiveCard('acc-1', 'card-9');

      expect(adapter.lastRequest.method, 'POST');
      expect(adapter.lastRequest.path, '/accounts/acc-1/vault/card-9/archive');
    });
  });
}
