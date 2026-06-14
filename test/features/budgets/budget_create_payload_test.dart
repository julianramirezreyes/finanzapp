import 'package:finanzapp_v2/features/budgets/data/budget_repository.dart';
import 'package:finanzapp_v2/features/budgets/data/budgets_provider.dart';
import 'package:finanzapp_v2/features/budgets/presentation/widgets/budget_form_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_dio_adapter.dart';

/// Pumps a host that opens [BudgetFormDialog] wired to a real [BudgetRepository]
/// (over [FakeDioAdapter]) using the SAME onSubmit create logic the tabs use:
/// create with months/isRecurrent and, for Hogar, householdId.
Future<FakeDioAdapter> _pumpCreateHost(
  WidgetTester tester, {
  required String? householdId,
}) async {
  final adapter = FakeDioAdapter(statusCode: 201, responseJson: const {});
  final repo = BudgetRepository(buildFakeDio(adapter));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [budgetRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        home: Scaffold(
          body: Consumer(
            builder: (context, ref, _) {
              return ElevatedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (ctx) => BudgetFormDialog(
                    onSubmit: (result) async {
                      await ref.read(budgetRepositoryProvider).createBudget(
                            category: result.name,
                            amount: result.limitAmount,
                            period: 'monthly',
                            type: result.type,
                            months: result.months,
                            isRecurrent: result.isRecurrent,
                            targetAmount: result.targetAmount,
                            householdId: householdId,
                          );
                      ref.invalidate(budgetsListProvider(householdId));
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                  ),
                ),
                child: const Text('abrir'),
              );
            },
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return adapter;
}

Future<void> _enterByLabel(
  WidgetTester tester,
  String label,
  String text,
) async {
  await tester.enterText(find.widgetWithText(TextField, label), text);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Personal — crear Fijo Mensual: POST /budgets con is_recurrent=true, months=1', (tester) async {
    final adapter = await _pumpCreateHost(tester, householdId: null);

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    await _enterByLabel(tester, 'Nombre', 'Didi');
    await _enterByLabel(tester, 'Monto mensual', '200000');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Guardar'));
    await tester.pumpAndSettle();

    expect(adapter.requests, hasLength(1));
    final body = adapter.lastRequest.json;
    expect(adapter.lastRequest.method, 'POST');
    expect(adapter.lastRequest.path, '/budgets');
    expect(body['is_recurrent'], true);
    expect(body['months'], 1);
    expect(body['amount'], 200000);
    expect(body['household_id'], isNull);
  });

  testWidgets('Personal — crear Meta (6 meses): POST con is_recurrent=false, months=6, amount=total', (tester) async {
    final adapter = await _pumpCreateHost(tester, householdId: null);

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Meta (X meses)'));
    await tester.pumpAndSettle();
    await _enterByLabel(tester, 'Nombre', 'Viaje');
    await _enterByLabel(tester, 'Meses', '6');
    await _enterByLabel(tester, 'Objetivo total', '600000');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Guardar'));
    await tester.pumpAndSettle();

    final body = adapter.lastRequest.json;
    expect(body['is_recurrent'], false);
    expect(body['months'], 6);
    expect(body['amount'], 600000);
    expect(body['household_id'], isNull);
  });

  testWidgets('Hogar — crear Meta: POST con household_id, is_recurrent=false, months=3', (tester) async {
    final adapter = await _pumpCreateHost(tester, householdId: 'house-9');

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Meta (X meses)'));
    await tester.pumpAndSettle();
    await _enterByLabel(tester, 'Nombre', 'Fondo Hogar');
    await _enterByLabel(tester, 'Meses', '3');
    await _enterByLabel(tester, 'Objetivo total', '900000');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Guardar'));
    await tester.pumpAndSettle();

    final body = adapter.lastRequest.json;
    expect(body['household_id'], 'house-9');
    expect(body['is_recurrent'], false);
    expect(body['months'], 3);
    expect(body['amount'], 900000);
  });
}
