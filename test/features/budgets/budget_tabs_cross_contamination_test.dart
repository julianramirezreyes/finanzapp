import 'package:finanzapp_v2/features/auth/presentation/auth_controller.dart';
import 'package:finanzapp_v2/features/budgets/presentation/household_budget_tab.dart';
import 'package:finanzapp_v2/features/budgets/presentation/personal_budget_tab.dart';
import 'package:finanzapp_v2/features/household/data/household_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import '../../support/budgets_tab_harness.dart';

final _currency = NumberFormat.currency(
  symbol: '\$',
  decimalDigits: 0,
  locale: 'es_CO',
);

/// R6.2/R7.2 — a copy-paste bug where one tab watches the OTHER family
/// instance (e.g. Personal accidentally reading
/// budgetsListProvider(household.id)) would be invisible to either single-tab
/// test in isolation, since each overrides only its OWN family instance. This
/// test stubs BOTH `budgetsListProvider(null)` AND
/// `budgetsListProvider(householdId)` simultaneously, with DISTINGUISHABLE
/// fixtures, in the SAME ProviderScope, and pumps both tabs side by side.
void main() {
  testWidgets(
    'Personal and Hogar tabs render ONLY their own budgetsListProvider instance totals',
    (tester) async {
      final household = fakeHousehold();

      // Personal: income 1,000,000 @ 50/30/20 -> Gastos cap 500,000.
      final personalConfig = fakePersonalConfig(
        personalIncome: 1000000,
        pctExpense: 50,
        pctSavings: 30,
        pctInvestment: 20,
      );
      final personalBudgets = [
        fakeBudgetMeta(id: 'p-e1', type: 'expense', monthlyQuota: 111111),
      ];

      // Hogar: incomeA+incomeB = 2,000,000 @ 50/30/20 -> Gastos cap 1,000,000.
      // Deliberately distinguishable from Personal's totals above.
      final householdConfig = fakeHouseholdConfig(
        householdId: household.id,
        incomeA: 1200000,
        incomeB: 800000,
        pctExpense: 50,
        pctSavings: 30,
        pctInvestment: 20,
      );
      final householdBudgets = [
        fakeBudgetMeta(id: 'h-e1', type: 'expense', monthlyQuota: 222222),
      ];

      final overrides = <Override>[
        userProvider.overrideWithValue(fakeUser(id: household.userAId)),
        householdProvider.overrideWith((ref) async => household),
        ...personalBudgetOverrides(
          config: personalConfig,
          budgets: personalBudgets,
        ),
        ...householdBudgetOverrides(
          household: household,
          config: householdConfig,
          budgets: householdBudgets,
        ),
      ];

      // Stacked vertically (not side by side) so each tab keeps the FULL
      // test viewport width — a side-by-side Row would squeeze each tab's
      // width in half and overflow unrelated widgets (e.g. BudgetCard),
      // which is irrelevant noise for this cross-contamination assertion.
      await pumpBudgetsScope(
        tester,
        overrides: overrides,
        child: const SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 500, child: PersonalBudgetTab()),
              SizedBox(height: 500, child: HouseholdBudgetTab()),
            ],
          ),
        ),
      );

      // Personal's own row shows ONLY its own totals (111,111 / 1,000,000).
      expect(
        find.text(
          '${_currency.format(111111)} / ${_currency.format(1000000)}',
        ),
        findsOneWidget,
      );
      // Personal's own chip shows ONLY its own allocation (111,111 / 500,000).
      expect(
        find.text(
          'Presup: ${_currency.format(111111)} / ${_currency.format(500000)}',
        ),
        findsOneWidget,
      );

      // Hogar's own row shows ONLY its own totals (222,222 / 2,000,000).
      expect(
        find.text(
          '${_currency.format(222222)} / ${_currency.format(2000000)}',
        ),
        findsOneWidget,
      );
      // Hogar's own chip shows ONLY its own allocation (222,222 / 1,000,000).
      expect(
        find.text(
          'Presup: ${_currency.format(222222)} / ${_currency.format(1000000)}',
        ),
        findsOneWidget,
      );

      // Cross-contamination guard: neither tab shows the OTHER's totals.
      expect(
        find.text(
          '${_currency.format(222222)} / ${_currency.format(1000000)}',
        ),
        findsNothing,
      );
      expect(
        find.text(
          '${_currency.format(111111)} / ${_currency.format(2000000)}',
        ),
        findsNothing,
      );
      expect(
        find.text(
          'Presup: ${_currency.format(222222)} / ${_currency.format(500000)}',
        ),
        findsNothing,
      );
      expect(
        find.text(
          'Presup: ${_currency.format(111111)} / ${_currency.format(1000000)}',
        ),
        findsNothing,
      );
    },
  );
}
