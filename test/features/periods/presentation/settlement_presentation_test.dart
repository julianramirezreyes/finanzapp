import 'package:finanzapp_v2/features/periods/presentation/settlement_presentation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats contribution percentages from returned settlement shares', () {
    expect(contributionLabel('Tu Parte', 60, 100), 'Tu Parte (60%)');
    expect(
      contributionLabel('Parte de tu Pareja', 40.5, 81.01),
      'Parte de tu Pareja (50%)',
    );
  });

  test('derives debtor and creditor explanation from returned ids', () {
    expect(
      settlementDirection(
        balance: 25,
        debtorId: 'user-b',
        creditorId: 'user-a',
        currentUserId: 'user-b',
      ),
      SettlementDirection.debtor,
    );
    expect(
      settlementDirection(
        balance: 25,
        debtorId: 'user-b',
        creditorId: 'user-a',
        currentUserId: 'user-a',
      ),
      SettlementDirection.creditor,
    );
  });
}
