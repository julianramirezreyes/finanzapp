import 'package:finanzapp_v2/features/budgets/domain/budget.dart';
import 'package:finanzapp_v2/features/budgets/presentation/budget_consumption.dart';
import 'package:flutter_test/flutter_test.dart';

Budget _budget({
  required String type,
  required double monthlyQuota,
  required double currentAmount,
}) {
  return Budget(
    id: 'id-$type-$currentAmount',
    userId: 'u1',
    category: 'cat-$type',
    limitAmount: monthlyQuota,
    period: 'monthly',
    type: type,
    currentAmount: currentAmount,
    monthlyQuota: monthlyQuota,
  );
}

void main() {
  group('summarizeBudgetConsumption — la barra refleja CONSUMO real', () {
    test(
      '11.1 — totalConsumed = Σ currentAmount, NO Σ monthlyQuota',
      () {
        // Quotas grandes (asignación) pero consumo real pequeño.
        final budgets = [
          _budget(type: 'expense', monthlyQuota: 500000, currentAmount: 120000),
          _budget(type: 'saving', monthlyQuota: 300000, currentAmount: 0),
        ];

        final summary = summarizeBudgetConsumption(
          budgets: budgets,
          totalBudgeted: 1000000,
        );

        // Refleja el gasto real (120000), no la suma de cuotas (800000).
        expect(summary.totalConsumed, 120000);
        expect(summary.totalConsumed, isNot(800000));
        expect(summary.consumedExpense, 120000);
        expect(summary.consumedSaving, 0);
        expect(summary.consumedInvestment, 0);
        expect(summary.remaining, 1000000 - 120000);
      },
    );

    test(
      '11.2 — mes nuevo sin transacciones -> progress ~= 0, no lleno',
      () {
        final budgets = [
          _budget(type: 'expense', monthlyQuota: 500000, currentAmount: 0),
          _budget(type: 'saving', monthlyQuota: 300000, currentAmount: 0),
          _budget(type: 'investment', monthlyQuota: 200000, currentAmount: 0),
        ];

        final summary = summarizeBudgetConsumption(
          budgets: budgets,
          totalBudgeted: 1000000,
        );

        expect(summary.totalConsumed, 0);
        expect(summary.progress, 0.0);
        expect(summary.remaining, 1000000);
      },
    );

    test(
      'progress = totalConsumed / totalBudgeted, clamp(0, 1.5)',
      () {
        final budgets = [
          _budget(type: 'expense', monthlyQuota: 500000, currentAmount: 400000),
          _budget(type: 'saving', monthlyQuota: 300000, currentAmount: 100000),
        ];

        final summary = summarizeBudgetConsumption(
          budgets: budgets,
          totalBudgeted: 1000000,
        );

        expect(summary.totalConsumed, 500000);
        expect(summary.progress, 0.5);
      },
    );

    test(
      'totalBudgeted == 0 -> progress 0 (sin division por cero)',
      () {
        final budgets = [
          _budget(type: 'expense', monthlyQuota: 0, currentAmount: 50000),
        ];

        final summary = summarizeBudgetConsumption(
          budgets: budgets,
          totalBudgeted: 0,
        );

        expect(summary.progress, 0.0);
        expect(summary.totalConsumed, 50000);
        expect(summary.remaining, -50000);
      },
    );

    test(
      'consumo por encima del plan -> progress clamp en 1.5',
      () {
        final budgets = [
          _budget(
            type: 'expense',
            monthlyQuota: 500000,
            currentAmount: 3000000,
          ),
        ];

        final summary = summarizeBudgetConsumption(
          budgets: budgets,
          totalBudgeted: 1000000,
        );

        expect(summary.progress, 1.5);
      },
    );
  });
}
