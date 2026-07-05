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
  group('PersonalBudgetTab — Presupuestado vs Plan row + chip captions', () {
    testWidgets(
      'i — row shows allocated/plan totals, chip caption shows allocated AND cap',
      (tester) async {
        // income 1,000,000 @ 50/30/20 -> caps 500k/300k/200k.
        final budgets = [
          fakeBudgetMeta(id: 'e1', type: 'expense', monthlyQuota: 200000),
          fakeBudgetMeta(id: 's1', type: 'saving', monthlyQuota: 100000),
          fakeBudgetMeta(id: 'i1', type: 'investment', monthlyQuota: 50000),
        ];

        await pumpPersonalBudgetTab(
          tester,
          config: fakePersonalConfig(),
          budgets: budgets,
        );

        expect(find.text('Presupuestado vs Plan'), findsOneWidget);
        final totalAllocated = 200000 + 100000 + 50000;
        const totalPlan = 500000 + 300000 + 200000;
        expect(
          find.text(
            '${_currency.format(totalAllocated)} / ${_currency.format(totalPlan)}',
          ),
          findsOneWidget,
        );

        // Chip caption shows BOTH the allocated amount and its cap.
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
        // pctInvestment = 0 -> investAmt cap = 0; an investment meta with
        // monthlyQuota > 0 is unconditionally over-allocated (R2.3/ADR-6).
        final budgets = [
          fakeBudgetMeta(id: 'e1', type: 'expense', monthlyQuota: 100000),
          fakeBudgetMeta(id: 'i1', type: 'investment', monthlyQuota: 10000),
        ];

        await pumpPersonalBudgetTab(
          tester,
          config: fakePersonalConfig(
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
        expect(
          find.text(
            'Presup: ${_currency.format(10000)} / ${_currency.format(0)}',
          ),
          findsOneWidget,
        );
        expect(
          _colorOfText(
            tester,
            'Presup: ${_currency.format(10000)} / ${_currency.format(0)}',
          ),
          AppColors.expense,
        );
      },
    );

    testWidgets(
      'iii — divergent tone: healthy on spend, over on allocation, same category',
      (tester) async {
        // saving cap = 300,000 (30% of 1,000,000). Allocated 400,000 (OVER),
        // but consumed only 50,000 (well under cap) -> consumption stays
        // healthy while allocation independently shows the alert tone.
        final budgets = [
          fakeBudgetMeta(
            id: 's1',
            type: 'saving',
            monthlyQuota: 400000,
            currentAmount: 50000,
          ),
        ];

        await pumpPersonalBudgetTab(
          tester,
          config: fakePersonalConfig(),
          budgets: budgets,
        );

        // Consumption chip number (healthy tone) is present.
        expect(find.text(_currency.format(50000)), findsOneWidget);
        expect(
          _colorOfText(tester, _currency.format(50000)),
          AppColors.savings,
        );

        // Allocation caption (alert tone), independent of the consumption tone.
        final allocationCaption =
            'Presup: ${_currency.format(400000)} / ${_currency.format(300000)}';
        expect(find.text(allocationCaption), findsOneWidget);
        expect(_colorOfText(tester, allocationCaption), AppColors.expense);
      },
    );
  });
}
