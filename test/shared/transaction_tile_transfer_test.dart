import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:finanzapp_v2/shared/ui/widgets/transaction_tile.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es_ES');
    await initializeDateFormatting('es_CO');
  });

  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('transfer renders with the swap icon and no +/- sign', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        TransactionTile(
          description: 'Pasar plata',
          category: 'Transferencia',
          amount: 50000,
          type: 'transfer',
          date: DateTime(2026, 6, 1),
        ),
      ),
    );

    expect(find.byIcon(Icons.swap_horiz_rounded), findsOneWidget);
    expect(find.byIcon(Icons.arrow_downward_rounded), findsNothing);
    expect(find.byIcon(Icons.arrow_upward_rounded), findsNothing);
    expect(find.textContaining('-'), findsNothing);
    expect(find.textContaining('+'), findsNothing);
  });

  testWidgets('expense keeps the down arrow and the minus sign', (tester) async {
    await tester.pumpWidget(
      wrap(
        TransactionTile(
          description: 'Compra',
          category: 'Gasto',
          amount: 1000,
          type: 'expense',
          date: DateTime(2026, 6, 1),
        ),
      ),
    );

    expect(find.byIcon(Icons.arrow_downward_rounded), findsOneWidget);
    expect(find.byIcon(Icons.swap_horiz_rounded), findsNothing);
    expect(find.textContaining('- '), findsOneWidget);
  });
}
