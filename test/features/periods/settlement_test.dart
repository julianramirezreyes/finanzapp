import 'package:finanzapp_v2/features/periods/domain/settlement.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Settlement Model', () {
    test('fromJson parses correctly', () {
      final json = {
        'total_amount': 100.0,
        'share_a': 50.0,
        'share_b': 50.0,
        'paid_by_a': 100.0,
        'paid_by_b': 0.0,
        'diff_a': 50.0,
        'diff_b': -50.0,
        'debtor_id': 'user_b',
        'creditor_id': 'user_a',
        'balance': 50.0,
      };

      final settlement = Settlement.fromJson(json);

      expect(settlement.totalAmount, 100.0);
      expect(settlement.shareA, 50.0);
      expect(settlement.debtorId, 'user_b');
      expect(settlement.balance, 50.0);
    });
  });
}
