import 'package:finanzapp_v2/features/periods/data/settlement_provider.dart';
import 'package:finanzapp_v2/features/periods/domain/period.dart';
import 'package:finanzapp_v2/features/periods/domain/settlement.dart';
import 'package:finanzapp_v2/features/periods/presentation/settlement_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'renders returned proportional shares instead of fixed percentages',
    (tester) async {
      const householdId = 'household-1';
      const periodId = 'period-1';
      final period = Period(
        id: periodId,
        householdId: householdId,
        year: 2026,
        month: 8,
        startDate: DateTime.utc(2026, 8, 1),
        endDate: DateTime.utc(2026, 8, 31),
        status: 'open',
      );
      final settlement = Settlement(
        totalAmount: 100,
        shareA: 60,
        shareB: 40,
        paidByA: 100,
        paidByB: 0,
        diffA: 40,
        diffB: -40,
        debtorId: 'user-b',
        creditorId: 'user-a',
        balance: 40,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settlementProvider((
              householdId: householdId,
              periodId: periodId,
            )).overrideWith((ref) async => settlement),
          ],
          child: MaterialApp(
            home: SettlementScreen(householdId: householdId, period: period),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tu Parte (60%)'), findsOneWidget);
      expect(find.text('Parte de tu Pareja (40%)'), findsOneWidget);
      expect(find.textContaining('Deudor debe a Acreedor'), findsOneWidget);
    },
  );
}
