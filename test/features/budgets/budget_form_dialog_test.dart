import 'package:finanzapp_v2/core/theme/app_colors.dart';
import 'package:finanzapp_v2/features/budgets/domain/budget.dart';
import 'package:finanzapp_v2/features/budgets/presentation/widgets/budget_form_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pumps [BudgetFormDialog] inside a Scaffold and records onSubmit results.
Future<List<BudgetFormResult>> _pumpDialog(
  WidgetTester tester, {
  Budget? existing,
  AllocationPreviewData? allocationPreview,
}) async {
  final results = <BudgetFormResult>[];
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: BudgetFormDialog(
          existing: existing,
          allocationPreview: allocationPreview,
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

/// Opens the category [DropdownButtonFormField] and selects the item whose
/// label is [categoryLabel] ("Gasto"/"Ahorro"/"Inversión"). `.last` picks the
/// overlay's menu entry when both the closed field and the open menu render
/// a matching Text simultaneously.
Future<void> _selectType(WidgetTester tester, String categoryLabel) async {
  await tester.tap(find.byType(DropdownButtonFormField<String>));
  await tester.pumpAndSettle();
  await tester.tap(find.text(categoryLabel).last);
  await tester.pumpAndSettle();
}

void main() {
  group('Crear', () {
    testWidgets(
      'E1 — Crear Fijo Mensual: label "Monto mensual", sin campo meses, payload recurrente',
      (tester) async {
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
      },
    );

    testWidgets(
      'E2 — Crear Meta: label "Objetivo total", ayuda cuota=100000, payload acumulativo',
      (tester) async {
        final results = await _pumpDialog(tester);

        await _selectMode(tester, 'Meta (X meses)');

        expect(
          find.widgetWithText(TextField, 'Objetivo total'),
          findsOneWidget,
        );
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
      },
    );

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
    testWidgets(
      'E5 — editar recurrente: modo Fijo + monto precargado = monthlyQuota',
      (tester) async {
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
      },
    );

    testWidgets(
      'E6 — editar acumulativa: modo Meta + monto=limitAmount + meses=months',
      (tester) async {
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

        expect(
          find.widgetWithText(TextField, 'Objetivo total'),
          findsOneWidget,
        );
        expect(find.widgetWithText(TextField, '900000'), findsOneWidget);
        expect(find.widgetWithText(TextField, '3'), findsOneWidget);
      },
    );

    testWidgets('E3 — editar acumulativa -> cambiar a Fijo y guardar', (
      tester,
    ) async {
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

    testWidgets('E4 — editar recurrente -> cambiar a Meta y guardar', (
      tester,
    ) async {
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

    testWidgets('E10 — en modo Meta, meses < 1 no llama onSubmit', (
      tester,
    ) async {
      final results = await _pumpDialog(tester);
      await _selectMode(tester, 'Meta (X meses)');
      await _enterByLabel(tester, 'Nombre', 'Y');
      await _enterByLabel(tester, 'Meses', '0');
      await _enterByLabel(tester, 'Objetivo total', '500000');
      await _tapSave(tester);
      expect(results, isEmpty);
    });
  });

  group('Allocation preview (PR3, R10-R13)', () {
    // Fixture snapshot: expense/saving/investment caps and OTHER (non-edited)
    // metas' allocated sums per category — mirrors the plain, provider-agnostic
    // shape `_showGoalDialog` (PR4) will inject (ADR-3).
    final snapshot = AllocationPreviewData(
      planCapByType: {
        'expense': 500000,
        'saving': 300000,
        'investment': 200000,
      },
      otherAllocatedByType: {
        'expense': 100000,
        'saving': 50000,
        'investment': 0,
      },
    );

    final zeroCapSnapshot = AllocationPreviewData(
      planCapByType: {'expense': 500000, 'saving': 0, 'investment': 200000},
      otherAllocatedByType: {'expense': 100000, 'saving': 0, 'investment': 0},
    );

    testWidgets(
      'P1 — preview shows the projected percentage against the cap (create, healthy)',
      (tester) async {
        await _pumpDialog(tester, allocationPreview: snapshot);

        await _enterByLabel(tester, 'Nombre', 'Renta');
        await _enterByLabel(tester, 'Monto mensual', '150000');

        // otherAllocated(expense)=100000 + projected 150000 = 250000 / 500000 = 50%.
        final text = tester.widget<Text>(
          find.textContaining('50% del plan de Gasto'),
        );
        expect(text.style?.color, AppColors.textSecondary);
      },
    );

    testWidgets(
      'P2 — preview shifts to alert tone when the projected total exceeds the cap',
      (tester) async {
        await _pumpDialog(tester, allocationPreview: snapshot);

        await _enterByLabel(tester, 'Nombre', 'Renta');
        await _enterByLabel(tester, 'Monto mensual', '450000');

        // otherAllocated(expense)=100000 + projected 450000 = 550000 / 500000 = 110%.
        final text = tester.widget<Text>(
          find.textContaining('110% del plan de Gasto'),
        );
        expect(text.style?.color, AppColors.expense);
      },
    );

    testWidgets(
      'P3 — zero cap with a positive projected allocation warns without a raw percentage or "Infinity"',
      (tester) async {
        await _pumpDialog(tester, allocationPreview: zeroCapSnapshot);

        await _selectType(tester, 'Ahorro');
        await _enterByLabel(tester, 'Nombre', 'Fondo');
        await _enterByLabel(tester, 'Monto mensual', '50000');

        expect(find.textContaining('Infinity'), findsNothing);
        expect(find.textContaining('%'), findsNothing);
        final text = tester.widget<Text>(
          find.textContaining('Sin plan asignado'),
        );
        expect(text.data, contains('Ahorro'));
        expect(text.style?.color, AppColors.expense);
      },
    );

    testWidgets(
      'P4 — zero cap with no projected allocation shows no warning and no percentage',
      (tester) async {
        await _pumpDialog(tester, allocationPreview: zeroCapSnapshot);

        await _selectType(tester, 'Ahorro');
        await _enterByLabel(tester, 'Nombre', 'Fondo');
        // No amount entered -> projected quota is 0.

        expect(find.textContaining('%'), findsNothing);
        expect(find.textContaining('Sin plan asignado'), findsNothing);
      },
    );

    testWidgets(
      'P5 — goal meta with months < 1 hides the preview (mirrors the Cuota mensual gate)',
      (tester) async {
        await _pumpDialog(tester, allocationPreview: snapshot);

        await _selectMode(tester, 'Meta (X meses)');
        await _enterByLabel(tester, 'Nombre', 'Viaje');
        await _enterByLabel(tester, 'Meses', '0');
        await _enterByLabel(tester, 'Objetivo total', '600000');

        expect(find.textContaining('% del plan de'), findsNothing);
        expect(find.textContaining('Sin plan asignado'), findsNothing);
      },
    );

    testWidgets(
      'P6 — CREATE mode: months, amount, toggle, and category each independently recompute the preview',
      (tester) async {
        await _pumpDialog(tester, allocationPreview: snapshot);
        await _enterByLabel(tester, 'Nombre', 'X');

        // Baseline in goal mode: months=4, amount=400000 -> quota=100000;
        // total = 100000(other) + 100000 = 200000 / 500000 = 40%.
        await _selectMode(tester, 'Meta (X meses)');
        await _enterByLabel(tester, 'Meses', '4');
        await _enterByLabel(tester, 'Objetivo total', '400000');
        expect(find.textContaining('40% del plan de Gasto'), findsOneWidget);

        // MONTHS trigger: 4 -> 2 => quota=200000; total=300000 / 500000 = 60%.
        await _enterByLabel(tester, 'Meses', '2');
        expect(find.textContaining('60% del plan de Gasto'), findsOneWidget);
        expect(find.textContaining('40% del plan de Gasto'), findsNothing);

        // AMOUNT trigger: 400000 -> 200000 (months=2) => quota=100000; total=200000 / 500000 = 40%.
        await _enterByLabel(tester, 'Objetivo total', '200000');
        expect(find.textContaining('40% del plan de Gasto'), findsOneWidget);
        expect(find.textContaining('60% del plan de Gasto'), findsNothing);

        // TOGGLE trigger: Meta -> Fijo Mensual; recurrent ignores months, quota=amount=200000;
        // total = 100000 + 200000 = 300000 / 500000 = 60%.
        await _selectMode(tester, 'Fijo Mensual');
        expect(find.textContaining('60% del plan de Gasto'), findsOneWidget);
        expect(find.textContaining('40% del plan de Gasto'), findsNothing);

        // CATEGORY trigger: Gasto -> Ahorro (cap=300000, other=50000); quota=200000 (recurrent);
        // total = 50000 + 200000 = 250000 / 300000 = 83%.
        await _selectType(tester, 'Ahorro');
        expect(find.textContaining('83% del plan de Ahorro'), findsOneWidget);
        expect(find.textContaining('60% del plan de Gasto'), findsNothing);
      },
    );

    testWidgets(
      'P7 — EDIT mode: amount/months changes recompute away from the stored quota (R11.3), self-exclusion holds',
      (tester) async {
        final existing = Budget(
          id: 'edit1',
          userId: 'u1',
          category: 'Renta',
          limitAmount: 900000,
          period: 'monthly',
          type: 'expense',
          isRecurrent: false,
          months: 3,
          monthlyQuota: 300000,
        );

        await _pumpDialog(
          tester,
          existing: existing,
          allocationPreview: snapshot,
        );

        // Preload: amount=900000, months=3 -> stored quota was 300000 (80%).
        expect(find.textContaining('80% del plan de Gasto'), findsOneWidget);

        // R11.3: change months only (900000/9=100000) -> total=200000/500000=40%,
        // clearly diverging from the stored 300000-based 80%.
        await _enterByLabel(tester, 'Meses', '9');
        expect(find.textContaining('40% del plan de Gasto'), findsOneWidget);
        expect(find.textContaining('80% del plan de Gasto'), findsNothing);

        // Change amount too (450000/9=50000) -> total=150000/500000=30%.
        await _enterByLabel(tester, 'Objetivo total', '450000');
        expect(find.textContaining('30% del plan de Gasto'), findsOneWidget);
        expect(find.textContaining('40% del plan de Gasto'), findsNothing);
      },
    );

    testWidgets(
      'P8 — category switch mid-create rebases to the new category cap and base sum (R10.4/R11.2)',
      (tester) async {
        await _pumpDialog(tester, allocationPreview: snapshot);

        await _enterByLabel(tester, 'Nombre', 'X');
        await _enterByLabel(tester, 'Monto mensual', '300000');
        // otherAllocated(expense)=100000 + 300000 = 400000/500000 = 80%.
        expect(find.textContaining('80% del plan de Gasto'), findsOneWidget);

        await _selectType(tester, 'Inversión');
        // otherAllocated(investment)=0 + 300000 = 300000/200000 = 150% (over cap -> alert).
        final text = tester.widget<Text>(
          find.textContaining('150% del plan de Inversión'),
        );
        expect(text.style?.color, AppColors.expense);
        expect(find.textContaining('80% del plan de Gasto'), findsNothing);
      },
    );

    testWidgets(
      'P9 — category switch mid-edit rebases to the new category, self-exclusion still holds (R11.2)',
      (tester) async {
        final existing = Budget(
          id: 'edit2',
          userId: 'u1',
          category: 'Suscripciones',
          limitAmount: 200000,
          period: 'monthly',
          type: 'expense',
          isRecurrent: true,
          months: 1,
          monthlyQuota: 200000,
        );

        await _pumpDialog(
          tester,
          existing: existing,
          allocationPreview: snapshot,
        );

        // Preload: recurrent amount=200000; other(expense)=100000 -> 300000/500000=60%.
        expect(find.textContaining('60% del plan de Gasto'), findsOneWidget);

        await _selectType(tester, 'Ahorro');
        // other(saving)=50000 (does NOT include this meta's own 200000) + 200000 = 250000/300000 = 83%.
        expect(find.textContaining('83% del plan de Ahorro'), findsOneWidget);
        expect(find.textContaining('60% del plan de Gasto'), findsNothing);
      },
    );

    testWidgets(
      'P10 — save is never blocked even while the preview is in warning state (R13.1)',
      (tester) async {
        final results = await _pumpDialog(tester, allocationPreview: snapshot);

        await _enterByLabel(tester, 'Nombre', 'Renta');
        await _enterByLabel(tester, 'Monto mensual', '450000');

        // Confirm the alert state is actually showing before saving.
        expect(find.textContaining('110% del plan de Gasto'), findsOneWidget);

        await _tapSave(tester);

        expect(results, hasLength(1));
        final r = results.single;
        expect(r.name, 'Renta');
        expect(r.monthlyQuota, 450000);
      },
    );

    testWidgets(
      'P11 — no snapshot provided degrades to no preview (existing call sites unaffected)',
      (tester) async {
        await _pumpDialog(tester);

        await _enterByLabel(tester, 'Nombre', 'Renta');
        await _enterByLabel(tester, 'Monto mensual', '150000');

        expect(find.textContaining('% del plan de'), findsNothing);
        expect(find.textContaining('Sin plan asignado'), findsNothing);
      },
    );

    testWidgets(
      'P12 — non-finite amount (overflowing literal) hides the preview without rendering "Infinity"/"NaN", save stays ungated (F1/F6a)',
      (tester) async {
        final results = await _pumpDialog(tester, allocationPreview: snapshot);

        await _enterByLabel(tester, 'Nombre', 'Renta');
        // Numeric TextField has no inputFormatters: double.tryParse accepts
        // this overflowing literal and yields double.infinity.
        await _enterByLabel(tester, 'Monto mensual', '1e400');

        expect(find.textContaining('Infinity'), findsNothing);
        expect(find.textContaining('NaN'), findsNothing);
        expect(find.textContaining('% del plan de'), findsNothing);
        expect(find.textContaining('Sin plan asignado'), findsNothing);

        // Documents existing (unchanged) form behavior: save is not gated by
        // amount finiteness — out of this slice's scope to change.
        await _tapSave(tester);
        expect(results, hasLength(1));
        expect(results.single.limitAmount.isFinite, isFalse);
      },
    );

    testWidgets(
      'P13 — projected total exactly at the cap boundary stays healthy, not alert (R5.2, F3)',
      (tester) async {
        await _pumpDialog(tester, allocationPreview: snapshot);

        await _enterByLabel(tester, 'Nombre', 'Renta');
        // otherAllocated(expense)=100000 + projected 400000 = 500000 == cap.
        await _enterByLabel(tester, 'Monto mensual', '400000');

        final text = tester.widget<Text>(
          find.textContaining('100% del plan de Gasto'),
        );
        expect(text.style?.color, AppColors.textSecondary);
        expect(text.style?.fontWeight, FontWeight.normal);
      },
    );

    testWidgets(
      'P14 — reverse category switch mid-edit (goal-type meta back to expense) rebases correctly (F6c)',
      (tester) async {
        final existing = Budget(
          id: 'edit3',
          userId: 'u1',
          category: 'Fondo',
          limitAmount: 100000,
          period: 'monthly',
          type: 'saving',
          isRecurrent: true,
          months: 1,
          monthlyQuota: 100000,
        );

        await _pumpDialog(
          tester,
          existing: existing,
          allocationPreview: snapshot,
        );

        // Preload: recurrent amount=100000, category=saving; other(saving)=50000
        // (self-exclusion already applied) -> 150000/300000 = 50%.
        expect(find.textContaining('50% del plan de Ahorro'), findsOneWidget);

        await _selectType(tester, 'Gasto');
        // other(expense)=100000 (this meta was never counted there, it was
        // 'saving') + 100000 = 200000/500000 = 40%.
        expect(find.textContaining('40% del plan de Gasto'), findsOneWidget);
        expect(find.textContaining('50% del plan de Ahorro'), findsNothing);
      },
    );
  });
}
