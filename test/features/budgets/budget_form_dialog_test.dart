import 'package:finanzapp_v2/features/budgets/domain/budget.dart';
import 'package:finanzapp_v2/features/budgets/presentation/widgets/budget_form_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pumps [BudgetFormDialog] inside a Scaffold and records onSubmit results.
Future<List<BudgetFormResult>> _pumpDialog(
  WidgetTester tester, {
  Budget? existing,
}) async {
  final results = <BudgetFormResult>[];
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: BudgetFormDialog(
          existing: existing,
          onSubmit: results.add,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return results;
}

/// Enters [text] into the TextField labelled [label].
Future<void> _enterByLabel(
  WidgetTester tester,
  String label,
  String text,
) async {
  await tester.enterText(find.widgetWithText(TextField, label), text);
  await tester.pumpAndSettle();
}

Future<void> _tapSave(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(ElevatedButton, 'Guardar'));
  await tester.pumpAndSettle();
}

Future<void> _selectMode(WidgetTester tester, String segmentLabel) async {
  await tester.tap(find.text(segmentLabel));
  await tester.pumpAndSettle();
}

void main() {
  group('Crear', () {
    testWidgets('E1 — Crear Fijo Mensual: label "Monto mensual", sin campo meses, payload recurrente', (tester) async {
      final results = await _pumpDialog(tester);

      // Default crear = Fijo Mensual.
      expect(find.widgetWithText(TextField, 'Monto mensual'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Meses'), findsNothing);

      await _enterByLabel(tester, 'Nombre', 'Didi');
      await _enterByLabel(tester, 'Monto mensual', '200000');
      await _tapSave(tester);

      expect(results, hasLength(1));
      final r = results.single;
      expect(r.name, 'Didi');
      expect(r.isRecurrent, true);
      expect(r.months, 1);
      expect(r.limitAmount, 200000);
      expect(r.monthlyQuota, 200000);
    });

    testWidgets('E2 — Crear Meta: label "Objetivo total", ayuda cuota=100000, payload acumulativo', (tester) async {
      final results = await _pumpDialog(tester);

      await _selectMode(tester, 'Meta (X meses)');

      expect(find.widgetWithText(TextField, 'Objetivo total'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Meses'), findsOneWidget);

      await _enterByLabel(tester, 'Nombre', 'Viaje');
      await _enterByLabel(tester, 'Meses', '6');
      await _enterByLabel(tester, 'Objetivo total', '600000');

      // Ayuda visual de cuota = 600000 / 6 = 100000.
      expect(find.textContaining('100.000'), findsWidgets);

      await _tapSave(tester);

      expect(results, hasLength(1));
      final r = results.single;
      expect(r.isRecurrent, false);
      expect(r.months, 6);
      expect(r.limitAmount, 600000);
      expect(r.monthlyQuota, 100000);
    });

    testWidgets('E7 — campo Meses visible SOLO en modo Meta', (tester) async {
      await _pumpDialog(tester);

      expect(find.widgetWithText(TextField, 'Meses'), findsNothing);

      await _selectMode(tester, 'Meta (X meses)');
      expect(find.widgetWithText(TextField, 'Meses'), findsOneWidget);

      await _selectMode(tester, 'Fijo Mensual');
      expect(find.widgetWithText(TextField, 'Meses'), findsNothing);
    });
  });

  group('Editar — precarga', () {
    testWidgets('E5 — editar recurrente: modo Fijo + monto precargado = monthlyQuota', (tester) async {
      final existing = Budget(
        id: 'b1',
        userId: 'u1',
        category: 'Arriendo',
        limitAmount: 150000,
        period: 'monthly',
        type: 'expense',
        isRecurrent: true,
        months: 1,
        monthlyQuota: 150000,
      );

      await _pumpDialog(tester, existing: existing);

      expect(find.widgetWithText(TextField, 'Monto mensual'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Meses'), findsNothing);
      expect(find.widgetWithText(TextField, '150000'), findsOneWidget);
    });

    testWidgets('E6 — editar acumulativa: modo Meta + monto=limitAmount + meses=months', (tester) async {
      final existing = Budget(
        id: 'b2',
        userId: 'u1',
        category: 'Viaje',
        limitAmount: 900000,
        period: 'monthly',
        type: 'saving',
        isRecurrent: false,
        months: 3,
        monthlyQuota: 300000,
        targetAmount: 900000,
      );

      await _pumpDialog(tester, existing: existing);

      expect(find.widgetWithText(TextField, 'Objetivo total'), findsOneWidget);
      expect(find.widgetWithText(TextField, '900000'), findsOneWidget);
      expect(find.widgetWithText(TextField, '3'), findsOneWidget);
    });

    testWidgets('E3 — editar acumulativa -> cambiar a Fijo y guardar', (tester) async {
      final existing = Budget(
        id: 'b3',
        userId: 'u1',
        category: 'Viaje',
        limitAmount: 600000,
        period: 'monthly',
        type: 'expense',
        isRecurrent: false,
        months: 6,
        monthlyQuota: 100000,
      );

      final results = await _pumpDialog(tester, existing: existing);

      await _selectMode(tester, 'Fijo Mensual');
      await _enterByLabel(tester, 'Monto mensual', '100000');
      await _tapSave(tester);

      final r = results.single;
      expect(r.isRecurrent, true);
      expect(r.months, 1);
      expect(r.limitAmount, 100000);
      expect(r.monthlyQuota, 100000);
    });

    testWidgets('E4 — editar recurrente -> cambiar a Meta y guardar', (tester) async {
      final existing = Budget(
        id: 'b4',
        userId: 'u1',
        category: 'Fondo',
        limitAmount: 200000,
        period: 'monthly',
        type: 'expense',
        isRecurrent: true,
        months: 1,
        monthlyQuota: 200000,
      );

      final results = await _pumpDialog(tester, existing: existing);

      await _selectMode(tester, 'Meta (X meses)');
      await _enterByLabel(tester, 'Meses', '4');
      await _enterByLabel(tester, 'Objetivo total', '800000');
      await _tapSave(tester);

      final r = results.single;
      expect(r.isRecurrent, false);
      expect(r.months, 4);
      expect(r.limitAmount, 800000);
      expect(r.monthlyQuota, 200000);
    });
  });

  group('Validaciones', () {
    testWidgets('E11 — nombre vacío no llama onSubmit', (tester) async {
      final results = await _pumpDialog(tester);
      await _enterByLabel(tester, 'Monto mensual', '200000');
      await _tapSave(tester);
      expect(results, isEmpty);
    });

    testWidgets('E11 — monto <= 0 no llama onSubmit', (tester) async {
      final results = await _pumpDialog(tester);
      await _enterByLabel(tester, 'Nombre', 'X');
      await _enterByLabel(tester, 'Monto mensual', '0');
      await _tapSave(tester);
      expect(results, isEmpty);
    });

    testWidgets('E10 — en modo Meta, meses < 1 no llama onSubmit', (tester) async {
      final results = await _pumpDialog(tester);
      await _selectMode(tester, 'Meta (X meses)');
      await _enterByLabel(tester, 'Nombre', 'Y');
      await _enterByLabel(tester, 'Meses', '0');
      await _enterByLabel(tester, 'Objetivo total', '500000');
      await _tapSave(tester);
      expect(results, isEmpty);
    });
  });
}
