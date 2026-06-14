import 'package:finanzapp_v2/features/budgets/presentation/widgets/budget_form_dialog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('mapBudgetAmounts — Fijo Mensual (recurrente)', () {
    test('limitAmount == monthlyQuota == amount, months=1, isRecurrent=true', () {
      final r = mapBudgetAmounts(
        name: 'Didi',
        type: 'expense',
        isRecurrent: true,
        months: 6, // ignorado en modo recurrente
        amount: 200000,
      );

      expect(r.name, 'Didi');
      expect(r.type, 'expense');
      expect(r.isRecurrent, true);
      expect(r.months, 1);
      expect(r.limitAmount, 200000);
      expect(r.monthlyQuota, 200000);
      expect(r.targetAmount, isNull, reason: 'expense no setea targetAmount');
    });

    test('saving recurrente setea targetAmount = amount', () {
      final r = mapBudgetAmounts(
        name: 'Ahorro',
        type: 'saving',
        isRecurrent: true,
        months: 1,
        amount: 150000,
      );

      expect(r.targetAmount, 150000);
    });
  });

  group('mapBudgetAmounts — Meta (X meses) acumulativa', () {
    test('limitAmount=total, monthlyQuota=total/months, isRecurrent=false', () {
      final r = mapBudgetAmounts(
        name: 'Viaje',
        type: 'expense',
        isRecurrent: false,
        months: 6,
        amount: 600000,
      );

      expect(r.isRecurrent, false);
      expect(r.months, 6);
      expect(r.limitAmount, 600000);
      expect(r.monthlyQuota, 100000);
      expect(r.targetAmount, isNull, reason: 'expense acumulativa no setea targetAmount');
    });

    test('saving/investment acumulativa setea targetAmount = total', () {
      final r = mapBudgetAmounts(
        name: 'Fondo',
        type: 'investment',
        isRecurrent: false,
        months: 4,
        amount: 800000,
      );

      expect(r.targetAmount, 800000);
      expect(r.monthlyQuota, 200000);
      expect(r.limitAmount, 800000);
    });

    test('months < 1 se clampa a 1 (evita division por cero)', () {
      final r = mapBudgetAmounts(
        name: 'Edge',
        type: 'expense',
        isRecurrent: false,
        months: 0,
        amount: 500000,
      );

      expect(r.months, 1);
      expect(r.monthlyQuota, 500000);
      expect(r.limitAmount, 500000);
    });
  });
}
