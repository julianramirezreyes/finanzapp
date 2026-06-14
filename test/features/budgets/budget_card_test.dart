import 'package:finanzapp_v2/features/budgets/domain/budget.dart';
import 'package:finanzapp_v2/features/budgets/presentation/widgets/budget_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// es_CO currency formats as "200.000 $" using a non-breaking space (U+00A0)
/// between the amount and the symbol, so matchers must use  .
const String _nb = ' ';

Future<void> _pumpCard(WidgetTester tester, Budget budget) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: BudgetCard(budget: budget, currentAmount: budget.currentAmount),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('E8 — acumulativa expense: progreso contra el TOTAL (limitAmount), no la cuota', (tester) async {
    final budget = Budget(
      id: 'b1',
      userId: 'u1',
      category: 'Viaje',
      limitAmount: 600000, // total
      period: 'monthly',
      type: 'expense',
      isRecurrent: false,
      months: 6,
      monthlyQuota: 100000,
      currentAmount: 300000,
    );

    await _pumpCard(tester, budget);

    // Header "300.000 $ / 600.000 $" contra el total, no contra la cuota 100.000.
    expect(
      find.textContaining('300.000$_nb\$ / 600.000$_nb\$'),
      findsOneWidget,
    );
    // Progreso 50%.
    expect(find.text('50%'), findsOneWidget);
    // Label de tipo acumulativo.
    expect(find.text('Meta (6 meses)'), findsOneWidget);
  });

  testWidgets('E8b — acumulativa saving: objetivo == limitAmount (no targetAmount divergente)', (tester) async {
    final budget = Budget(
      id: 'b2',
      userId: 'u1',
      category: 'Fondo',
      limitAmount: 800000,
      period: 'monthly',
      type: 'saving',
      isRecurrent: false,
      months: 4,
      monthlyQuota: 200000,
      targetAmount: 800000,
      currentAmount: 400000,
    );

    await _pumpCard(tester, budget);

    expect(
      find.textContaining('400.000$_nb\$ / 800.000$_nb\$'),
      findsOneWidget,
    );
    expect(find.text('50%'), findsOneWidget);
  });

  testWidgets('E9 — recurrente: progreso contra la cuota mensual (sin cambio)', (tester) async {
    final budget = Budget(
      id: 'b3',
      userId: 'u1',
      category: 'Arriendo',
      limitAmount: 200000,
      period: 'monthly',
      type: 'expense',
      isRecurrent: true,
      months: 1,
      monthlyQuota: 200000,
      currentAmount: 100000,
    );

    await _pumpCard(tester, budget);

    expect(
      find.textContaining('100.000$_nb\$ / 200.000$_nb\$'),
      findsOneWidget,
    );
    expect(find.text('50%'), findsOneWidget);
    expect(find.text('Fijo Mensual'), findsOneWidget);
  });
}
