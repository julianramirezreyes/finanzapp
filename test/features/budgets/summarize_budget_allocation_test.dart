import 'package:finanzapp_v2/features/budgets/domain/budget.dart';
import 'package:finanzapp_v2/features/budgets/presentation/budget_allocation.dart';
import 'package:flutter_test/flutter_test.dart';

Budget _budget({
  required String type,
  required double monthlyQuota,
  bool isRecurrent = true,
  int months = 1,
  String? id,
}) {
  return Budget(
    id: id ?? 'id-$type-$monthlyQuota-$isRecurrent-$months',
    userId: 'u1',
    category: 'cat-$type',
    limitAmount: monthlyQuota,
    period: 'monthly',
    type: type,
    monthlyQuota: monthlyQuota,
    isRecurrent: isRecurrent,
    months: months,
  );
}

void main() {
  group(
    'summarizeBudgetAllocation — reflects PLANNED allocation (monthlyQuota), not real consumption',
    () {
      test(
        '(a) no budgets -> allocated 0 for all three categories, no over flags',
        () {
          final summary = summarizeBudgetAllocation(
            budgets: const [],
            expensePlan: 500000,
            savingPlan: 300000,
            investPlan: 200000,
          );

          expect(summary.allocatedExpense, 0);
          expect(summary.allocatedSaving, 0);
          expect(summary.allocatedInvestment, 0);
          expect(summary.isExpenseOver, isFalse);
          expect(summary.isSavingOver, isFalse);
          expect(summary.isInvestmentOver, isFalse);
          expect(summary.hasAnyCategoryOver, isFalse);
          expect(summary.totalAllocated, 0);
          expect(summary.totalPlan, 1000000);
          expect(summary.remaining, 1000000);
        },
      );

      test('(b) allocated under cap -> not over for any category', () {
        final budgets = [
          _budget(type: 'expense', monthlyQuota: 300000),
          _budget(type: 'saving', monthlyQuota: 100000),
          _budget(type: 'investment', monthlyQuota: 50000),
        ];

        final summary = summarizeBudgetAllocation(
          budgets: budgets,
          expensePlan: 500000,
          savingPlan: 300000,
          investPlan: 200000,
        );

        expect(summary.allocatedExpense, 300000);
        expect(summary.isExpenseOver, isFalse);
        expect(summary.isSavingOver, isFalse);
        expect(summary.isInvestmentOver, isFalse);
        expect(summary.hasAnyCategoryOver, isFalse);
      });

      test(
        '(c) allocated exactly at cap -> NOT over (strict greater-than, matches R1.2/R5.2)',
        () {
          final budgets = [_budget(type: 'expense', monthlyQuota: 500000)];

          final summary = summarizeBudgetAllocation(
            budgets: budgets,
            expensePlan: 500000,
            savingPlan: 300000,
            investPlan: 200000,
          );

          expect(summary.allocatedExpense, 500000);
          expect(summary.isExpenseOver, isFalse);
        },
      );

      test(
        '(d) Gastos over its cap -> only isExpenseOver true, hasAnyCategoryOver true',
        () {
          final budgets = [
            _budget(type: 'expense', monthlyQuota: 600000),
            _budget(type: 'saving', monthlyQuota: 100000),
          ];

          final summary = summarizeBudgetAllocation(
            budgets: budgets,
            expensePlan: 500000,
            savingPlan: 300000,
            investPlan: 200000,
          );

          expect(summary.isExpenseOver, isTrue);
          expect(summary.isSavingOver, isFalse);
          expect(summary.isInvestmentOver, isFalse);
          expect(summary.hasAnyCategoryOver, isTrue);
        },
      );

      test(
        '(d2) Ahorro over its cap -> only isSavingOver true (no per-category exemption, R5.1)',
        () {
          final budgets = [
            _budget(type: 'expense', monthlyQuota: 100000),
            _budget(type: 'saving', monthlyQuota: 400000),
          ];

          final summary = summarizeBudgetAllocation(
            budgets: budgets,
            expensePlan: 500000,
            savingPlan: 300000,
            investPlan: 200000,
          );

          expect(summary.isExpenseOver, isFalse);
          expect(summary.isSavingOver, isTrue);
          expect(summary.isInvestmentOver, isFalse);
          expect(summary.hasAnyCategoryOver, isTrue);
        },
      );

      test(
        '(e) zero cap WITH allocation -> over-flag true, no cap>0 suppression (R2.3)',
        () {
          final budgets = [_budget(type: 'investment', monthlyQuota: 50000)];

          final summary = summarizeBudgetAllocation(
            budgets: budgets,
            expensePlan: 500000,
            savingPlan: 300000,
            investPlan: 0,
          );

          expect(summary.allocatedInvestment, 50000);
          expect(summary.isInvestmentOver, isTrue);
          expect(summary.hasAnyCategoryOver, isTrue);
        },
      );

      test(
        '(e2) zero cap with NO allocation -> over-flag false (R2.2)',
        () {
          final summary = summarizeBudgetAllocation(
            budgets: const [],
            expensePlan: 500000,
            savingPlan: 300000,
            investPlan: 0,
          );

          expect(summary.allocatedInvestment, 0);
          expect(summary.isInvestmentOver, isFalse);
          expect(summary.hasAnyCategoryOver, isFalse);
        },
      );

      test(
        '(f) recurrent and goal metas fold identically into the same category sum (R9)',
        () {
          final budgets = [
            _budget(
              type: 'expense',
              monthlyQuota: 200000,
              isRecurrent: true,
              id: 'recurrent',
            ),
            _budget(
              type: 'expense',
              monthlyQuota: 150000,
              isRecurrent: false,
              months: 3,
              id: 'goal',
            ),
          ];

          final summary = summarizeBudgetAllocation(
            budgets: budgets,
            expensePlan: 500000,
            savingPlan: 300000,
            investPlan: 200000,
          );

          expect(summary.allocatedExpense, 350000);
          expect(summary.isExpenseOver, isFalse);
        },
      );

      test(
        '(g) global totals sum the three categories, progress clamps to [0, 1.5]',
        () {
          final budgets = [
            _budget(type: 'expense', monthlyQuota: 900000),
            _budget(type: 'saving', monthlyQuota: 300000),
            _budget(type: 'investment', monthlyQuota: 200000),
          ];

          final summary = summarizeBudgetAllocation(
            budgets: budgets,
            expensePlan: 500000,
            savingPlan: 300000,
            investPlan: 200000,
          );

          expect(summary.totalAllocated, 1400000);
          expect(summary.totalPlan, 1000000);
          expect(summary.remaining, 1000000 - 1400000);
          expect(summary.progress, 1.4);
        },
      );

      test(
        '(g2) progress clamps at 1.5 when allocation greatly exceeds the plan',
        () {
          final budgets = [_budget(type: 'expense', monthlyQuota: 3000000)];

          final summary = summarizeBudgetAllocation(
            budgets: budgets,
            expensePlan: 500000,
            savingPlan: 0,
            investPlan: 0,
          );

          expect(summary.progress, 1.5);
        },
      );

      test(
        'totalPlan == 0 -> progress 0 (no division by zero)',
        () {
          final summary = summarizeBudgetAllocation(
            budgets: const [],
            expensePlan: 0,
            savingPlan: 0,
            investPlan: 0,
          );

          expect(summary.progress, 0.0);
          expect(summary.totalAllocated, 0);
          expect(summary.remaining, 0);
        },
      );
    },
  );
}
