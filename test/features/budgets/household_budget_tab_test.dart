import 'package:finanzapp_v2/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import '../../support/budgets_tab_harness.dart';

final _currency = NumberFormat.currency(
  symbol: '\$',
  decimalDigits: 0,
  locale: 'es_CO',
);

Color? _colorOfText(WidgetTester tester, String text) {
  return tester.widget<Text>(find.text(text)).style?.color;
}

void main() {
  group('HouseholdBudgetTab — Presupuestado vs Plan row + chip captions', () {
    testWidgets(
      'i — row shows allocated/plan totals, chip caption shows allocated AND cap',
      (tester) async {
        final household = fakeHousehold();
        // incomeA + incomeB = 1,000,000 @ 50/30/20 -> caps 500k/300k/200k.
        final budgets = [
          fakeBudgetMeta(id: 'e1', type: 'expense', monthlyQuota: 200000),
          fakeBudgetMeta(id: 's1', type: 'saving', monthlyQuota: 100000),
          fakeBudgetMeta(id: 'i1', type: 'investment', monthlyQuota: 50000),
        ];

        await pumpHouseholdBudgetTab(
          tester,
          household: household,
          config: fakeHouseholdConfig(
            householdId: household.id,
            incomeA: 600000,
            incomeB: 400000,
          ),
          budgets: budgets,
        );

        expect(find.text('Presupuestado vs Plan'), findsOneWidget);
        const totalAllocated = 200000 + 100000 + 50000;
        const totalPlan = 500000 + 300000 + 200000;
        expect(
          find.text(
            '${_currency.format(totalAllocated)} / ${_currency.format(totalPlan)}',
          ),
          findsOneWidget,
        );
        expect(
          find.text(
            'Presup: ${_currency.format(200000)} / ${_currency.format(500000)}',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'ii — row/chip shift to alert tone when hasAnyCategoryOver, incl. zero-cap-with-allocation',
      (tester) async {
        final household = fakeHousehold();
        final budgets = [
          fakeBudgetMeta(id: 'e1', type: 'expense', monthlyQuota: 100000),
          fakeBudgetMeta(id: 'i1', type: 'investment', monthlyQuota: 10000),
        ];

        await pumpHouseholdBudgetTab(
          tester,
          household: household,
          config: fakeHouseholdConfig(
            householdId: household.id,
            incomeA: 500000,
            incomeB: 500000,
            pctExpense: 50,
            pctSavings: 50,
            pctInvestment: 0,
          ),
          budgets: budgets,
        );

        expect(
          _colorOfText(tester, 'Presupuestado vs Plan'),
          AppColors.expense,
        );
        final chipCaption =
            'Presup: ${_currency.format(10000)} / ${_currency.format(0)}';
        expect(find.text(chipCaption), findsOneWidget);
        expect(_colorOfText(tester, chipCaption), AppColors.expense);
      },
    );

    testWidgets(
      'iii — divergent tone: healthy on spend, over on allocation, same category',
      (tester) async {
        final household = fakeHousehold();
        final budgets = [
          fakeBudgetMeta(
            id: 's1',
            type: 'saving',
            monthlyQuota: 400000,
            currentAmount: 50000,
          ),
        ];

        await pumpHouseholdBudgetTab(
          tester,
          household: household,
          config: fakeHouseholdConfig(
            householdId: household.id,
            incomeA: 600000,
            incomeB: 400000,
          ),
          budgets: budgets,
        );

        expect(find.text(_currency.format(50000)), findsOneWidget);
        expect(
          _colorOfText(tester, _currency.format(50000)),
          AppColors.savings,
        );

        final allocationCaption =
            'Presup: ${_currency.format(400000)} / ${_currency.format(300000)}';
        expect(find.text(allocationCaption), findsOneWidget);
        expect(_colorOfText(tester, allocationCaption), AppColors.expense);
      },
    );

    testWidgets(
      'full household plan basis: cap reflects (incomeA + incomeB), never a per-member split',
      (tester) async {
        final household = fakeHousehold();
        // Distinguishable incomes: incomeA=700k, incomeB=300k. Cap for
        // expense (50%) must reflect the FULL sum (1,000,000 * 0.5 = 500k),
        // never a per-member share (e.g. NOT incomeA*0.5 = 350k).
        final budgets = [
          fakeBudgetMeta(id: 'e1', type: 'expense', monthlyQuota: 450000),
        ];

        await pumpHouseholdBudgetTab(
          tester,
          household: household,
          config: fakeHouseholdConfig(
            householdId: household.id,
            incomeA: 700000,
            incomeB: 300000,
            pctExpense: 50,
            pctSavings: 30,
            pctInvestment: 20,
          ),
          budgets: budgets,
        );

        // Full-household-basis cap (500k): 450k allocated is UNDER cap, not over.
        final fullBasisCaption =
            'Presup: ${_currency.format(450000)} / ${_currency.format(500000)}';
        expect(find.text(fullBasisCaption), findsOneWidget);
        expect(_colorOfText(tester, fullBasisCaption), AppColors.textSecondary);

        // A per-member split (incomeA alone, 700k*0.5=350k) would wrongly
        // read 450k as OVER — assert that caption is NOT what's rendered.
        final perMemberCaption =
            'Presup: ${_currency.format(450000)} / ${_currency.format(350000)}';
        expect(find.text(perMemberCaption), findsNothing);
      },
    );
  });
}
